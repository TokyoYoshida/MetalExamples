//
//  VideoWriter.swift
//  RecordingVideoExample
//
//  Created by TokyoYoshida on 2021/03/27.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoWriter : NSObject{
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    
    init(fileUrl:NSURL!, height:Int, width:Int, channels:Int, samples:Float64){
        fileWriter = try? AVAssetWriter(outputURL: fileUrl as URL, fileType: AVFileType.mov)
        
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : width,
            AVVideoHeightKey : height
        ];
        videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        fileWriter.add(videoInput)
        
        let audioOutputSettings: [String: Any] = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey : channels,
            AVSampleRateKey : samples,
            AVEncoderBitRateKey : 128000
        ]
        audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = true
        fileWriter.add(audioInput)
    }
    
    func write(sample: CMSampleBuffer, isVideo: Bool){
        if CMSampleBufferDataIsReady(sample) {
            if fileWriter.status == AVAssetWriter.Status.unknown {
                let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                fileWriter.startWriting()
                fileWriter.startSession(atSourceTime: startTime)
            }
            if fileWriter.status == AVAssetWriter.Status.failed {
                return
            }
            if isVideo {
                if videoInput.isReadyForMoreMediaData {
                    videoInput.append(sample)
                }
            }else{
                if audioInput.isReadyForMoreMediaData {
                    audioInput.append(sample)
                }
            }
        }
    }
    
    func finish(callback: @escaping () -> Void){
        fileWriter.finishWriting(completionHandler: callback)
    }
}
