//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"
#import <qr_reader/QRCodeReaderPlugin.h>
#import <shared_preferences/SharedPreferencesPlugin.h>

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [QRCodeReaderPlugin registerWithRegistrar:[registry registrarForPlugin:@"QRCodeReaderPlugin"]];
  [FLTSharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTSharedPreferencesPlugin"]];
}

@end
