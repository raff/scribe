//
//  ViewController.swift
//  Scribe
//
//  Created by Raffaele Sena on 8/7/17.
//  Copyright © 2017 Raffaele Sena. All rights reserved.
//

import AudioKit
import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var audioPlotter: EZAudioPlot!
    @IBOutlet weak var position: NSSlider!
    @IBOutlet weak var playTime: NSTextField!
    
    @IBOutlet weak var speed: NSSlider!
    @IBOutlet weak var displaySpeed: NSTextField!
    @IBOutlet weak var pitch: NSSlider!
    @IBOutlet weak var displayPitch: NSTextField!
    
    private var audioPlayer: AKAudioPlayer!
    private var timePlayer: AKTimePitch!
    private var panner: AKPanner!
    private var booster: AKBooster!
    
    @IBOutlet private var audioInputPlot: EZAudioPlot!
    
    enum PlayStates {
        case play, pause, stop
    }

    private var playState: PlayStates = .stop
    
    @IBAction func changeSpeed(_ sender: NSSlider) {
        timePlayer.rate = sender.doubleValue / 100.0
        displaySpeed.stringValue = String(format: "%3d%%", sender.integerValue)
    }
    
    @IBAction func changePitch(_ sender: NSSlider) {
        timePlayer.pitch = sender.doubleValue * 100.0 // in cents
        displayPitch.stringValue = String(format: "%+d", sender.integerValue)
    }
    
    
    @IBAction func changePan(_ sender: NSPopUpButton) {
        // panner.pan = Double(sender.selectedTag())
        
        switch sender.selectedTag() {
        case -1: // left
            booster.leftGain = 1.0
            booster.rightGain = 0.0
            
        case 1: // right
            booster.leftGain = 0.0
            booster.rightGain = 1.0
            
        default: // stereo
            booster.leftGain = 1.0
            booster.rightGain = 1.0
        }
    }

    @IBAction func positionSlider(_ sender: NSSlider) {
        audioPlayer.scheduledTime = sender.doubleValue
    }
    
    @IBAction func playPause(_ sender: NSButton) {
        if playState == .play {
            play(p: .pause)
        } else {
            play(p: .play)
        }
    }
    
    @IBAction func stopPlay(_ sender: NSButton) {
        play(p: .stop)
    }
    
    @IBAction func goBack(_ sender: NSButton) {
        if audioPlayer.currentTime > 3.0 {
            NSLog("back to %f", audioPlayer.currentTime - 3.0)
            audioPlayer.pause()
            audioPlayer.play(from: audioPlayer.currentTime - 3.0, to: 0, when: 0)
        }
    }
    
    @IBAction func goForward(_ sender: Any) {
        NSLog("forward to %f", audioPlayer.currentTime + 3.0)
        audioPlayer.pause()
        audioPlayer.play(from: audioPlayer.currentTime + 3.0, to: 0, when: 0)
    }
    
    @IBAction func loadFile(_ sender: NSButton) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Select audio file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["aiff", "mp3", "wav"];
        
        if (dialog.runModal() == NSModalResponseOK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                play(p: .stop)

                do {
                    let af = try AKAudioFile(forReading: result!)
                    try audioPlayer.replace(file: af)
                } catch {
                    NSLog("error loading \(result!.path)")
                }
                
                play(p: .play)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let af = try AKAudioFile()
            audioPlayer = try AKAudioPlayer(file: af)
        } catch {
            NSLog("error creating audio player")
        }
        
        _ = AKPlaygroundLoop(every: 1 / 60.0) {
            if self.audioPlayer.duration > 0 {
                self.position.doubleValue = self.audioPlayer.playhead
                
                let p = self.audioPlayer.playhead
                
                self.playTime.stringValue = String(format: "%02d:%02d.%03d", Int(p/60), Int(p) % 60, Int(p.truncatingRemainder(dividingBy: 1.0) * 1000.0))
                
                if self.audioPlayer.duration != self.position.maxValue {
                    self.position.maxValue = self.audioPlayer.duration
                }
            }
        }
        
        speed.minValue = 0.0
        speed.maxValue = 100.0
        speed.integerValue = 100
        speed.allowsTickMarkValuesOnly = true
        speed.numberOfTickMarks = 20
        speed.tickMarkPosition = NSTickMarkPosition.below
        
        pitch.minValue = -12
        pitch.maxValue = +12
        pitch.integerValue = 0
        pitch.allowsTickMarkValuesOnly = true
        pitch.numberOfTickMarks = 25
        pitch.tickMarkPosition = NSTickMarkPosition.below
        
        timePlayer = AKTimePitch(audioPlayer)
        //panner = AKPanner(timePlayer)
        //AudioKit.output = panner
        
        booster = AKBooster(timePlayer)
        AudioKit.output = booster
        
        setupPlot()
    }
    
    override func viewWillAppear() {
        AudioKit.start()
        booster.start()
        timePlayer.start()
    }
    
    override func viewWillDisappear() {
        AudioKit.stop()
        booster.stop()
        timePlayer.stop()
        
        exit(0)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func play(p: PlayStates) {
        switch p {
        case .play:
            if playState == .stop {
                audioPlotter.resetHistoryBuffers()
                audioPlayer.start()
                NSLog("start play")
            } else if !audioPlayer.isPlaying {
                audioPlayer.resume()
                NSLog("resume play")
            }
        
        case .pause:
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                NSLog("pause play")
            }
            
        case .stop:
            audioPlayer.stop()
            NSLog("stop play")
        }
        
        playState = p
    }
    
    func setupPlot() {
        let plot = AKNodeOutputPlot(timePlayer, frame: audioPlotter.bounds)
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        //  plot.shouldOptimizeForRealtimePlot = false
        plot.color = NSColor.blue
        plot.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        
        audioPlotter.addSubview(plot)
    }
    
}
