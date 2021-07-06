//
//  VideoRecorder.swift
//  RecordingVideoExample
//
//  Created by TokyoYoshida on 2021/03/27.
//

import Foundation
import AVFoundation
import Photos

typealias ImageBufferHandler = ((_ imageBuffer: CVPixelBuffer, _ timestamp: CMTime, _ outputBuffer: CVPixelBuffer?) -> ())
class FrameVideoRecorder: NSObject {

    var imageBufferHandler: ImageBufferHandler?

    fileprivate let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    fileprivate let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    let captureSession = AVCaptureSession()
    fileprivate let fileOutput = AVCaptureMovieFileOutput()
    fileprivate var completionHandler: ((Bool, Error?) -> Void)?
    let lockQueue =  DispatchQueue(label: "LockQueue")
    let recordingQueue =  DispatchQueue(label: "RecordingQueue")

    var height:Int?
    var width:Int?

    var videoWriter : VideoWriter?

    var isCapturing = false
    var isPaused = false
    var isDiscontinue = false
    var fileIndex = 0

    var timeOffset = CMTimeMake(value: 0, timescale: 0)
    var lastAudioPts: CMTime?

    var isRecording: Bool {
        get {
            isCapturing
        }
    }
    
    func prepare() throws {
        func connectInput() throws {
            let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)

            self.videoDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            let videoInput = try AVCaptureDeviceInput(device: videoDevice!)
            self.captureSession.addInput(videoInput)

            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            self.captureSession.addInput(audioInput);
        }
        func connectOutput() {
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: self.recordingQueue)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]
            self.captureSession.addOutput(videoDataOutput)

            height = videoDataOutput.videoSettings["Height"] as! Int?
            width = videoDataOutput.videoSettings["Width"] as! Int?

            let audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(self, queue: self.recordingQueue)
            self.captureSession.addOutput(audioDataOutput)
        }
        func setCameraImageQuality() {
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
        }
        if videoDevice == nil || audioDevice == nil {
            fatalError("Device cannot initialize.")
        }
        
        try connectInput()
        connectOutput()
        setCameraImageQuality()
//        captureSession.addOutput(fileOutput)
        captureSession.startRunning()
    }
    
    func startRecording(fileURL: URL, completionHandler: @escaping ((Bool, Error?) -> Void)) {
        self.completionHandler = completionHandler
        lockQueue.sync() {
            if !self.isCapturing{
                self.isPaused = false
                self.isDiscontinue = false
                self.isCapturing = true
                self.timeOffset = CMTimeMake(value: 0, timescale: 0)
            }
        }
    }
    
    func stopRecording() {
        self.lockQueue.sync() {
            if self.isCapturing{
                self.isCapturing = false
                DispatchQueue.main.async {
                    self.videoWriter!.finish { () -> Void in
                        self.videoWriter = nil
//                        PHPhotoLibrary.shared().performChanges({
//                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.filePathUrl() as URL)
//                        }) { [weak self] completed, error in
//                            self?.completionHandler?(completed ,error)
//                            self?.fileIndex += 1
//                        }
                    }
                    
                }
            }
        }
    }
}


extension FrameVideoRecorder: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video\(self.fileIndex).mp4"
        return filePath
    }
    
    func filePathUrl() -> NSURL! {
        return NSURL(fileURLWithPath: self.filePath())
    }
    

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.lockQueue.sync() {
            if !self.isCapturing || self.isPaused {
                return
            }
            
            if let imageBufferHandler = imageBufferHandler, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                imageBufferHandler(imageBuffer, timestamp, nil)
            }

            let isVideo = output is AVCaptureVideoDataOutput
            
            if self.videoWriter == nil && !isVideo {
                let fileManager = FileManager()
                if fileManager.fileExists(atPath: self.filePath()) {
                    do {
                        try fileManager.removeItem(atPath: self.filePath())
                    } catch _ {
                    }
                }
                
                let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
                guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!) else {
                    fatalError("Cannot get absd.")
                }
                
                self.videoWriter = VideoWriter(
                    fileUrl: self.filePathUrl(),
                    height: self.height!, width: self.width!,
                    channels: Int(asbd.pointee.mBytesPerFrame),
                    samples: asbd.pointee.mSampleRate
                )
            }
            
            if self.isDiscontinue {
                if isVideo {
                    return
                }

                var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                let isAudioPtsValid = self.lastAudioPts!.flags.intersection(.valid)
                if isAudioPtsValid.rawValue != 0 {
                    let isTimeOffsetPtsValid = self.timeOffset.flags.intersection(.valid)
                    if isTimeOffsetPtsValid.rawValue != 0 {
                        pts = CMTimeSubtract(pts, self.timeOffset);
                    }
                    let offset = CMTimeSubtract(pts, self.lastAudioPts!);

                    if (self.timeOffset.value == 0)
                    {
                        self.timeOffset = offset;
                    }
                    else
                    {
                        self.timeOffset = CMTimeAdd(self.timeOffset, offset);
                    }
                }
                self.lastAudioPts!.flags = CMTimeFlags()
                self.isDiscontinue = false
            }
            
            var buffer = sampleBuffer
            if self.timeOffset.value > 0 {
                buffer = self.ajustTimeStamp(sample: sampleBuffer, offset: self.timeOffset)
            }

            if !isVideo {
                var pts = CMSampleBufferGetPresentationTimeStamp(buffer)
                let dur = CMSampleBufferGetDuration(buffer)
                if (dur.value > 0)
                {
                    pts = CMTimeAdd(pts, dur)
                }
                self.lastAudioPts = pts
            }
            
            self.videoWriter?.write(sample: buffer, isVideo: isVideo)
        }
    }
    
    func ajustTimeStamp(sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count);
        
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(value: 0, timescale: 0), presentationTimeStamp: CMTimeMake(value: 0, timescale: 0), decodeTimeStamp: CMTimeMake(value: 0, timescale: 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: count, arrayToFill: &info, entriesNeededOut: &count);

        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }

        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &out);
        return out!
    }
}

extension FrameVideoRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        func saveToLibrary() {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }) { [weak self] completed, error in
                self?.completionHandler?(completed ,error)
            }
        }
        saveToLibrary()
    }
}
