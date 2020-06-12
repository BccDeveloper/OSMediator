//
//  OSMediator.swift
//  MediatorDemo
//
//  Created by 张飞 on 2019/5/17.
//  Copyright © 2019 张飞. All rights reserved.
//

import UIKit

let kOSMediatorTargetModuleName = "kOSMediatorTargetModuleName"

let kResult = "result"
let kNative = "native"


class OSMediator: NSObject {
    
    private lazy var cachedTarget:[String:NSObject] = {
        return [:]
    }()
    
    public static let `default` = OSMediator()
    
    private override init() {
        super.init()
    }
    
}

extension OSMediator{
    
    public func remotePerformAction(url:URL) -> Any?{
        
        var params = [String:Any]()
        let urlString = url.query
        
        if let urlString = urlString?.components(separatedBy: "&") {
            
            for item in urlString{
                
                let elts = item.components(separatedBy: "=")
                if elts.count >= 2,let first = elts.first,let last = elts.last{
                    params[first] = last
                }
                
            }
        }
        
        let actionName = url.path.replacingOccurrences(of: "/", with: "")
        if actionName.hasPrefix(kNative){
            
            return false
        }
        
        return localPerformAction(targetName: url.host ?? "" , actionName: actionName, params: params)
        
    }
    
    public func localPerformAction(targetName:String,actionName:String,params:[String:Any],shouldCacheTarget:Bool = true) -> Any?{
        
        
        let moduleName = params[kOSMediatorTargetModuleName]
        
        var targetString = ""
        
        if let moduleName = moduleName as? String,moduleName.count > 0{
            
            targetString = String(format: "%@.Target_%@", moduleName,targetName)
        } else{
            targetString = String(format: "Target_%@",targetName)
        }
        
        
        var target = cachedTarget[targetString]
        
        if target == nil,let targetType = NSClassFromString(targetString) as? NSObject.Type{
            
            target = targetType.init()
            
        }
        
        let actionString = String(format: "Action_", actionName)
        
        let action = NSSelectorFromString(actionString)
        
        if target == nil {
            
            safePerformNoTargetAction(targetName: targetString, actionName: actionString, originParams: params)
            
            return nil
            
        }
        
        
        if (shouldCacheTarget) {
            self.cachedTarget[targetString] = target
        }
        
        if target!.responds(to: action) == true {
            
            return safePerformAction(target: target!, action: action, params: params)
            
        }else{
            
            let action = NSSelectorFromString("notFound:")
            
            if target!.responds(to: action) == true{
                
                return safePerformAction(target: target!, action: action, params: params)
                
            }else{
                
                safePerformNoTargetAction(targetName: targetString, actionName: actionString, originParams: params)
                cachedTarget.removeValue(forKey: targetString)
                return nil
            }
            
        }
        
    }
    
    public func releaseCachedTarget(targetName:String){
        
        let targetString = String.init(format: "Target_%@", targetName)
        self.cachedTarget.removeValue(forKey: targetString)
        
    }
    
}

extension OSMediator{
    
    private func safePerformNoTargetAction(targetName:String,actionName:String,originParams:[String:Any]){
        
        let action = NSSelectorFromString("Action_response:")
        
        var target:NSObject?
        
        if let targetType = NSClassFromString("Target_NoTargetAction") as? NSObject.Type{
            
            target = targetType.init()
            
        }
        
        var params = [String:Any]()
        params["originParams"] = params
        params["originTarget"] = targetName
        params["originAction"] = actionName
        
        guard let _ = target,target!.responds(to: action) == false else { return}
        
        
        safePerformAction(target: target!, action: action, params: params)
        
    }
    
    @discardableResult
    private func safePerformAction(target:NSObject,action:Selector,params:[String:Any]) -> AnyObject?{
        
        let result = target.perform(action, with: params)
        
        return result?.takeUnretainedValue()
        
    }
    
    
}
