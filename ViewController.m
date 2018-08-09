//
//  ViewController.m
//  VPNTest
//
//  Created by JoeXu on 2018/6/1.
//  Copyright © 2018年 YM. All rights reserved.
//

#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>
#import "OAXVPNManager.h"

@interface ViewController ()
@property (nonatomic,strong) NEVPNManager *vpnManager;
@end


static NSString *const serviceName = @"let.us.try.vpn.in.ipsec"; //随便自定义
static NSString *const vpnPwdIdentifier = @"vpnPassword"; //keychain的密码存取key
static NSString *const vpnPrivateKeyIdentifier = @"sharedKey"; //keychain中共享密钥存取key

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[OAXVPNManager sharedManager] prepare:^(NSError *error) {
       
        if (error){
            return ;
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[OAXVPNManager sharedManager] connect:^(NSError *_error) {
                NSLog(@"%@",_error);
            }];
        });
        
    }];
    
    
    return;
    NEVPNManager *manager = [NEVPNManager sharedManager];
    
    [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
       
        NEVPNProtocolIPSec *conf;
        if ([manager.protocolConfiguration isKindOfClass:[NEVPNProtocolIPSec class]]){
            conf = (NEVPNProtocolIPSec *)manager.protocolConfiguration;
        }
        if (conf == nil) {
            conf = [[NEVPNProtocolIPSec alloc] init];
        }
        conf.serverAddress = @"10.200.11.108"; //vpn服务器地址
        conf.username = @"zach"; //vpn账户
        conf.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret; //选择共享密钥方式
        conf.sharedSecretReference = [self searchKeychainCopyMatchingWithIdentifier:vpnPrivateKeyIdentifier]; //从keychain中获取共享密钥
        conf.passwordReference = [self searchKeychainCopyMatchingWithIdentifier:vpnPwdIdentifier]; //从keychain中获取密码
        manager.protocolConfiguration = conf;
        manager.localizedDescription = @"走你vpn";
        manager.enabled = YES; //allow对话框后自动选中当前vpn
        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            NSLog(@"done: \(error.debugDescription)");
            if (error == nil) {
                self.vpnManager = manager;
            }

        }];

        
    }];
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}



/**
 * 搜索对应的keychain数据
 */
- (NSData *)searchKeychainCopyMatchingWithIdentifier:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [self newSearchDictionaryWithIdentifier:identifier];
    [searchDictionary addEntriesFromDictionary:
     @{
       (NSString *)kSecMatchLimit:(NSString *)kSecMatchLimitOne,
       (NSString *)kSecReturnPersistentRef:@(YES)
       }];

    CFTypeRef result = nil;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    
    NSData *o = (__bridge NSData *)result;
    return o;
}

/**
 * 创建对应的keychain数据
 */
- (BOOL)createKeychainValueWithPassword:(NSString *)password identifier:(NSString *)identifier
{
    NSMutableDictionary *dictionary = [self newSearchDictionaryWithIdentifier:identifier];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:passwordData forKey:(NSString *)kSecValueData];
    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, nil);
    return status == errSecSuccess;
}



/**
 * 存取keychain用到的dictionary
 */
- (NSMutableDictionary *)newSearchDictionaryWithIdentifier:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    [searchDictionary addEntriesFromDictionary:
     @{(NSString *)kSecClass:(NSString *)kSecClassGenericPassword,
       (NSString *)kSecAttrGeneric:encodedIdentifier,
       (NSString *)kSecAttrAccount:encodedIdentifier,
       (NSString *)kSecAttrService:serviceName
       
       }];
    return searchDictionary;
}


@end
