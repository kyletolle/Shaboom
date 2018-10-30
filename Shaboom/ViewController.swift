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

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var listenButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
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
            recorder.record()
            listenButton.setTitle("Done", for: .normal)
        } else {
            // Stop recording
            recorder.stop()
            listenButton.setTitle("Listen", for: .normal)

            do {
                try audioSession.setActive(false)
            } catch {
                os_log("Could not stop listening...", log: OSLog.default, type: .debug)
            }

            
            if (recorder != nil) {
                // Let's get the file URL for the recorder's audio snippet
                let url_string = String(describing: recorder!.url)
                // Finally figured out how to log runtime stuff in swift:
                // https://stackoverflow.com/questions/53025698/using-os-log-to-log-function-arguments-or-other-dynamic-data
                os_log("file url: %@", log: OSLog.default, type: .debug, url_string)
            }
            // Here is where we want to get the audio data out of the file
            // And send it to the web server.
        }
        
        playButton.isEnabled = false
    }
    @IBAction func playButtonTapped(_ sender: UIButton) {
        if (recorder != nil && !recorder.isRecording) {
            do {
                try player = AVAudioPlayer(contentsOf: recorder.url)
            } catch {
                os_log("Could not play sound...", log: OSLog.default, type: .debug)
            }
            
            player.delegate = self
            player.play()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Disable the play button when app launches
        playButton.isEnabled = false
        
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
        
        let recordSettings: [String:NSNumber] = [
            AVFormatIDKey : NSNumber(integerLiteral: Int(kAudioFormatMPEG4AAC)),
            AVSampleRateKey : NSNumber(floatLiteral: 44100.0),
            AVNumberOfChannelsKey : NSNumber(integerLiteral: 2)
        ]
        
        // Set the audio file
        let filename = "RecordedAudioSnippet.m4a"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let pathComponents = [paths.last ?? "", filename as String]
        let recordedFileURL = NSURL.fileURL(withPathComponents: pathComponents)
        
        // Initiate and prepare the recorder
        do {
            os_log("Trying to create an audio recorder...", log: OSLog.default, type: .debug)
            try recorder = AVAudioRecorder(url: recordedFileURL!, settings: recordSettings)
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
        listenButton.setTitle("Listen", for: .normal)
        
        playButton.isEnabled = true
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
