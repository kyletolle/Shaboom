//
//  ViewController.swift
//  Shaboom
//
//  Created by Kyle Tolle on 10/10/18.
//  Copyright © 2018 Kyle Tolle. All rights reserved.
//

import UIKit
import AVFoundation
import os.log
import Alamofire
import Foundation

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var listenButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer!
    
    // MARK: Actions
    
    @IBAction func listenButtonTapped(_ sender: UIButton) {
        if (player != nil && player.isPlaying) {
            player.stop()
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        if (recorder != nil && !recorder.isRecording) {
            do {
                try audioSession.setActive(true)
            } catch {
                os_log("Could not start listening...", log: OSLog.default, type: .debug)
            }

            // Start recording
            // TODO: We should be able to record for a certain number of seconds as well.
            //recorder.record()
            recorder.record(forDuration: TimeInterval(exactly: 5)!)
            listenButton.setTitle("Listening for 5s", for: .normal)
            listenButton.isEnabled = false
            songNameLabel.text = ""
        } else {
            // Stop recording
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        songNameLabel.text = ""
        
        // Use this file url when you want to read from an existing file...
        let audioFileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "MyAudioMemo", ofType: "m4a") ?? "")
        do {
            os_log("Trying to create an audio player...", log: OSLog.default, type: .debug)
            //let myAudioMemo = try AVAudioFile(forReading: audioFileURL)
            try player = AVAudioPlayer(contentsOf: audioFileURL)
        } catch {
            os_log("The audio player could not read the contents of the file", log: OSLog.default, type: .debug)
            return
        }
        
        // Get the player ready
        player.delegate = self
        player.prepareToPlay()
        
        // Set up the audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            os_log("Could not set up audio session", log: OSLog.default, type: .debug)
        }
        
        // Okay, this let us record in m4a, but what about if we want to use wav?
//        let recordSettings: [String:NSNumber] = [
//            AVFormatIDKey : NSNumber(integerLiteral: Int(kAudioFormatMPEG4AAC)),
//            AVSampleRateKey : NSNumber(floatLiteral: 44100.0),
//            AVNumberOfChannelsKey : NSNumber(integerLiteral: 2)
//        ]
        // This uses an empty dictionary.
        //let recordSettings: [String:NSNumber] = [:]
        
        // Set the audio file
        //let filename = "RecordedAudioSnippet.m4a"
        let filename = "RecordedAudioSnippet.wav"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let pathComponents = [paths.last ?? "", filename as String]
        let recordedFileURL = NSURL.fileURL(withPathComponents: pathComponents)
        
        // Initiate and prepare the recorder
        do {
            os_log("Trying to create an audio recorder...", log: OSLog.default, type: .debug)
            // Instead of using m4a audio from above, let's try to use wav.
            // try recorder = AVAudioRecorder(url: recordedFileURL!, settings: recordSettings)
            try recorder = AVAudioRecorder(url: recordedFileURL!, format: AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!)
        } catch {
            os_log("Could not set up recorder", log: OSLog.default, type: .debug)
        }
        
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recorder.stop()
        
        listenButton.setTitle("Listen for 5s", for: .normal)
        listenButton.isEnabled = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            os_log("Could not stop listening...", log: OSLog.default, type: .debug)
        }
        
        // Let's get the file URL for the recorder's audio snippet
        let urlString = String(describing: recorder.url)
        // Finally figured out how to log runtime stuff in swift:
        // https://stackoverflow.com/questions/53025698/using-os-log-to-log-function-arguments-or-other-dynamic-data
        os_log("file url: %@", log: OSLog.default, type: .debug, urlString)
        
        // Here is where we want to upload the file to the web server
        // Using code from: https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#uploading-multipart-form-data
        Alamofire.upload(
            multipartFormData: { multipartFormData in multipartFormData.append(recorder.url, withName: "file")
            },
            to: "http://localhost:5000/wav_upload",
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON {
                        response in
                        
                        //debugPrint(response)
                        if let json = response.result.value {
                            debugPrint("########################")
                            debugPrint("########################")
                            debugPrint("########################")
                            debugPrint("We are trying to print the JSON response...")
                            print("Response JSON: \(json)")
                            let jsonArray = json as? [String: Any]
                            let jsonResult = jsonArray!["result"] as! String
                            print("Result: \(jsonResult)")
                            self.songNameLabel.text = jsonResult
                            debugPrint("########################")
                            debugPrint("########################")
                            debugPrint("########################")
                        }
                        
                        
//                        do {
//                            let parsedData = try JSONSerialization.jsonObject(with: response!) as! [String: Any]
//                            let result = parsedData["result"] as! String
//                        } catch {
//                            os_log("Could not parse json...", log: OSLog.default, type: .debug)
//                        }
                        
                        //let json = try? JSONSerialization.jsonObject(with: apiResponse, options: [])
                        
//                        let jsonResponse = try? JSONSerialization.jsonObject(with: response, options: .allowFragments) as? [String: AnyObject]
//                        // Printing the json in the console
//                        let result = jsonResponse!.value(forKey: "result")!
//                        let songName = (result as? String)!
//                        print(songName)
//                        songNameLabel.text = songName
                    }
                case .failure(let encodingError):
                    print(encodingError)
                    
                }
            }
        )
        
        
        //                do {
        //                    // This is getting nuts. I still don't know how to get the binary data I need out of things...
        //                    let audioFile = try AVAudioFile(forReading: recorder!.url)
        //                    let fileFormat = audioFile.fileFormat
        //                    let frameCapacity = UInt32(audioFile.length)
        //                    let audioPCMBuffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCapacity)
        //                    try audioFile.read(into: audioPCMBuffer!)
        //                    let audioData = audioPCMBuffer?.int16ChannelData
        //                    ExtAudioFileRead(<#T##inExtAudioFile: ExtAudioFileRef##ExtAudioFileRef#>, <#T##ioNumberFrames: UnsafeMutablePointer<UInt32>##UnsafeMutablePointer<UInt32>#>, <#T##ioData: UnsafeMutablePointer<AudioBufferList>##UnsafeMutablePointer<AudioBufferList>#>)
        //                    //os_log("audioData: %@", log: OSLog.default, type: .debug, audioData!)
        //
        //                } catch {
        //                    os_log("Could not get binary audio data...", log: OSLog.default, type: .debug)
        //                }
    }
    
    // MARK: AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let alert = UIAlertController(title: "Done", message: "Finished playing the sound!", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK",
                          style: .default,
                          handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}
