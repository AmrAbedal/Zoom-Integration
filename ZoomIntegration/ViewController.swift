//
//  ViewController.swift
//  ZoomIntegration
//
//  Created by Amr AbdelWahab on 7/3/20.
//  Copyright © 2020 Orcas. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}





import Foundation
import MobileRTC

let zoomTag = "Zoom Tag --->"

protocol ZoomCallbacks :class{
    func getUserName()-> String
    func getUserPassword()-> String
    
    func onZoomMeetingStatusChanged(state: MobileRTCMeetingState)
    func onCallStarted(callID: String, password: String)
    func onCallEnded(callID: String)
    func onZoomReady()
    func onZoomLoginFail()
}


class ZoomManager: NSObject, MobileRTCAuthDelegate, MobileRTCMeetingServiceDelegate {
     static let instance = ZoomManager()
    
    private lazy var zoom = MobileRTC.shared()
    private let appKey = "appKey"
    private let appSecret = "appSecret"
    
    private weak var callbacks :ZoomCallbacks? = nil
    private (set) var isLoggedIn = false
    // MARK: - public api
    static var shared : ZoomManager{
        return instance
    }
    
    func addCallback(callbacks :ZoomCallbacks){
        self.callbacks = callbacks
    }
    
    func startZoom(navigationController: UINavigationController?){
        initializeSDK(navigationController)
        authZoom()
    }
    
    func joinMeeting(meetingNo :String, meetingPassword:String, meetingTitle :String, userName:String,token:String? = nil){
        if let meetingService = zoom.getMeetingService() {
            meetingService.customizeMeetingTitle(meetingTitle)
            meetingService.delegate = self
            let paramDict = [
                kMeetingParam_Username : userName,
                kMeetingParam_MeetingNumber : meetingNo,
                kMeetingParam_MeetingPassword :meetingPassword,
                kMeetingParam_UserToken: token
            ]
            
            let ret = meetingService.joinMeeting(with: paramDict)
            print("\(zoomTag) meetingService.startMeeting is: \(ret.rawValue)")
        }
    }
    
    func login(){
        if let authService = zoom.getAuthService(),
            let userName = callbacks?.getUserName(),
            let userPassword = callbacks?.getUserPassword(){
            authService.delegate = self
            authService.login(withEmail: userName, password: userPassword, rememberMe: true)
        }
    }
    
    func startMeeting(meetingTitle :String = "Hello Zoom", userName:String = "User"){
        if let meetingService = zoom.getMeetingService() {
            meetingService.customizeMeetingTitle(meetingTitle)
            meetingService.delegate = self
            let user = MobileRTCMeetingStartParam4LoginlUser.init()
            user.meetingNumber = ""
            user.isAppShare = false
            let ret = meetingService.startMeeting(with: user)
            
            print("\(zoomTag) meetingService.startMeeting is: \(ret.rawValue)")
        }
    }
    
    
    // MARK: - Initialize Zoom
    private func initializeSDK(_ navigationController: UINavigationController?) {
        let initContext = MobileRTCSDKInitContext()
        initContext.domain = "zoom.us"
        initContext.enableLog = true
        
        let isInitialized = zoom.initialize(initContext)
        print("\(zoomTag) SDK initialization is \(isInitialized)")
        zoom.setMobileRTCRootController(navigationController)
    }
    
    
    private func authZoom(){
        if let authService = zoom.getAuthService(){
            authService.delegate = self
            authService.clientKey = appKey
            authService.clientSecret = appSecret
            
            authService.sdkAuth()
        }
    }
    
    // MARK: - MobileRTCAuthDelegate
    func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        print("\(zoomTag) onMobileRTCAuthReturn : \(returnValue.rawValue)")
        if returnValue.rawValue == 0 {
            callbacks?.onZoomReady()
        }
        
    }
    
    func onMobileRTCLoginReturn(_ returnValue: Int) {
        if returnValue == 0{
            isLoggedIn = true
            callbacks?.onZoomReady()
        }else{
            callbacks?.onZoomLoginFail()
        }
    }
    
    
    //MARK: - MobileRTCMeetingServiceDelegate
    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        switch state.rawValue {
        case MobileRTCMeetingState_Idle.rawValue:
            callbacks?.onCallEnded(callID: MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber)
        case MobileRTCMeetingState_Connecting.rawValue:
            break
        case MobileRTCMeetingState_InMeeting.rawValue:
            callbacks?.onCallStarted(callID: MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber, password: MobileRTCInviteHelper.sharedInstance().rawMeetingPassword)
        case MobileRTCMeetingState_WebinarPromote.rawValue:
            break
        case MobileRTCMeetingState_WebinarDePromote.rawValue:
            break
        default:
            break
        }
        
        callbacks?.onZoomMeetingStatusChanged(state: state)
    }
    
}
