#import "IcloudPlugin.h"
#if __has_include(<icloud/icloud-Swift.h>)
#import <icloud/icloud-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "icloud-Swift.h"
#endif

@implementation IcloudPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIcloudPlugin registerWithRegistrar:registrar];
}
@end
