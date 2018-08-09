//
//  OAXVPNManager.m
//  VPNTest
//
//  Created by JoeXu on 2018/6/4.
//  Copyright © 2018年 YM. All rights reserved.
//

#import "OAXVPNManager.h"
#import <NetworkExtension/NetworkExtension.h>

static NSString *const kOAXVPNServiceName = @"OAX_VPN"; //服务器名称
static NSString *const kOAXVPNServiceAddress = @"104.129.181.59"; //服务器地址
static int kOAXVPNServicePort = 443; //服务器端口
static NSString *const kOAXVPNServiceMethod = @"AES256CFB"; //服务器验证方式
static NSString *const kOAXVPNPassword = @"ZGE1YmU1Mm"; //密码;


@interface OAXVPNManager()
{
    
}
@property(nonatomic,strong) NETunnelProviderManager *vpnManager;
@property(nonatomic,assign) NEVPNStatus vpnStatus;

@end
@implementation OAXVPNManager

+ (instancetype)sharedManager
{
    static OAXVPNManager *object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init_sharedManager];
    });
    return object;
}
- (instancetype)init_sharedManager
{
    self = [super init];return self;
}

- (void)__observeManager
{
//    if (self.vpnManager){
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
//    }
//    self.vpnManager = manager;
//    if (manager){
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(__notifyVPNStatusChanged:) name:NEVPNStatusDidChangeNotification object:manager.connection];
//    }
}
- (void)__notifyVPNStatusChanged:(NSNotification *)notif
{
    switch (self.vpnManager.connection.status) {
        case NEVPNStatusConnected:
            self.vpnStatus = NEVPNStatusConnected;
            break;
        case NEVPNStatusConnecting:
        case NEVPNStatusReasserting:
            self.vpnStatus = NEVPNStatusConnecting;
            break;
        case NEVPNStatusDisconnecting:
            self.vpnStatus = NEVPNStatusDisconnecting;
            break;
        case NEVPNStatusDisconnected:
        case NEVPNStatusInvalid:
            self.vpnStatus = NEVPNStatusDisconnected;
            break;
    }
}

static void __LoadAndCreateProviderManager(void(^complete)(NETunnelProviderManager *manager,NSError *error))
{
    __LoadProviderManager(^(NETunnelProviderManager *manager) {
        if (manager){
            complete(manager,nil);
        }else{
            
            manager = __CreateProviderManager();
            [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable _error) {
                if(_error){
                    if (complete){complete(manager,nil);}
                }else{
                    [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable __error) {
                        if(__error){
                            if (complete){complete(nil,__error);}
                        }else{
                            if (complete){complete(manager,nil);}
                        }
                    }];
                }
            }];
            
        }
        
        
    });
}


static void __LoadProviderManager(void(^complete)(NETunnelProviderManager *manager))
{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        for (NETunnelProviderManager *aManager in managers) {
            if ([[aManager localizedDescription] isEqualToString:kOAXVPNServiceName]){
                complete(aManager);
                return;
            }
        }
        complete(nil);
    }];
}

static NETunnelProviderManager *__CreateProviderManager()
{
    NETunnelProviderManager *manager = [[NETunnelProviderManager alloc] init];
    manager.localizedDescription = kOAXVPNServiceName;

    NETunnelProviderProtocol *conf = [[NETunnelProviderProtocol alloc] init];
    manager.protocolConfiguration = conf;
    manager.enabled = YES;

    __SetRulerConf(manager);
    return manager;
}


static void __SetRulerConf(NETunnelProviderManager *manager)
{
    NETunnelProviderProtocol *conf = (NETunnelProviderProtocol *)manager.protocolConfiguration;
    
    conf.serverAddress = @"127.0.0.1";
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[@"ss_address"] = kOAXVPNServiceAddress;
    d[@"ss_port"] = @(kOAXVPNServicePort);
    d[@"ss_method"] = kOAXVPNServiceMethod;
    d[@"ss_password"] = kOAXVPNPassword;
    d[@"ymal_conf"] = __GetRuleConf();

    conf.providerConfiguration = d;
    manager.protocolConfiguration = conf;
}
static NSString *__GetRuleConf()
{
    NSString *path = [NSBundle.mainBundle pathForResource:@"NEKitRule" ofType:@"conf"];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}
@end




@implementation OAXVPNManager (Operate)

- (void)prepare:(void (^)(NSError *))complete
{
    __LoadAndCreateProviderManager(^(NETunnelProviderManager *manager,NSError *error) {
        if (error == nil){
            [self __observeManager];
        }
        
        if (complete){
            complete(error);
        }
    });
    
}

- (void)connect:(void (^)(NSError *))complete
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __LoadProviderManager(^(NETunnelProviderManager *manager) {
            
            NSError *conn_error;
            [manager.connection startVPNTunnelWithOptions:@{} andReturnError:&conn_error];
            if (complete){complete(conn_error);}
            
        });
    });
    
}

@end

