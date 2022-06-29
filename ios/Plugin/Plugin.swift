import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(SmartScannerPlugin)
public class SmartScannerPlugin: CAPPlugin {
    
    public var call: CAPPluginCall?
    public var lastFrame: CMSampleBuffer?

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": value
        ])
    }
    @objc func executeScanner(_ call: CAPPluginCall) {
        self.call = call
        let options = call.getObject("options") ?? [:]
        let mode = options["mode"] as! String        
        self.showCamera(mode)
        /*if(mode=="barcode"){
            self.showCamera(mode)
            /*call.resolve(["scanner_result":["value": "DIGITHOTEL_OKMANYOLVASO|digithotel|demo|1938"]])*/
        }else if(mode=="mrz"){
            call.resolve(["scanner_result":[
                "code": "TypeI",
                "code1": 73,
                "code2": 68,
                "dateOfBirth": myDate.toString(),
                "documentNumber": "AB1234567",
                "expirationDate": "08/11/29",
                "format": "MRTD_TD1",
                "givenNames": " SALI",
                "mrz": "lol",
                "image": "/data/user/0/org.idpass.smartscanner/cache/Scanner-20201123103638.jpg",
                "issuingCountry": "IRQ",
                "nationality": "IRQ",
                "sex": "Male",
                "surname": ""
              ]])
        }*/
    
    }
}
