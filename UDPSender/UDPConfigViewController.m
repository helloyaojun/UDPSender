//
//  UDPConfigViewController.m
//  TouchspriteDemo
//
//  Created by 姚君 on 16/3/28.
//  Copyright © 2016年 certus. All rights reserved.
//

#import "UDPConfigViewController.h"
#import "AsyncUdpSocket.h"

#define SERVER_CONFIG @"serverConfig"
#define PORT_CONFIG @"portConfig"

@interface UDPConfigViewController () {
    
    AsyncUdpSocket *asyncUdpSocket;
    NSMutableDictionary *sendDic;
}


@property (strong, nonatomic) IBOutlet UITextField *serverTextField;
@property (strong, nonatomic) IBOutlet UITextField *portTextField;

@end


@implementation UDPConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    NSError *error;
    if (!asyncUdpSocket) {
        asyncUdpSocket = [[AsyncUdpSocket alloc] initIPv4];
    }
    [asyncUdpSocket setDelegate:self];
    [asyncUdpSocket enableBroadcast:YES error:&error];
    if ([asyncUdpSocket bindToPort:14099 error:&error]) {
        [asyncUdpSocket joinMulticastGroup:@"255.255.255.255" error:&error];
    }
    [asyncUdpSocket receiveWithTimeout:-1 tag:2];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    [self sendUdpMessage];
}

- (void)sendUdpMessage {
    
    [sendDic setObject:@"设备号" forKey:@"deviceid"];
    [sendDic setObject:@"触动版本号" forKey:@"tsversion"];
    [sendDic setObject:@"设备名" forKey:@"devname"];

    NSData *data = [NSJSONSerialization dataWithJSONObject:sendDic options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *port = [sendDic objectForKey:@"port"];
    NSString *server = [sendDic objectForKey:@"ip"];
    [[NSUserDefaults standardUserDefaults] setObject:server forKey:SERVER_CONFIG];
    [[NSUserDefaults standardUserDefaults] setObject:port forKey:PORT_CONFIG];
    [[NSUserDefaults standardUserDefaults] synchronize];

    UInt16 portInt16 = (UInt16)port.intValue;
    [asyncUdpSocket sendData:data toHost:[sendDic objectForKey:@"ip"] port:portInt16 withTimeout:-1 tag:2];

}

#pragma mark - AsyncUdpSocketDelegate

//已接收到消息
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port{
    if(data){
        [asyncUdpSocket receiveWithTimeout:-1 tag:2];
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        _serverTextField.text = [dictionary objectForKey:@"ip"];
        _portTextField.text = [dictionary objectForKey:@"port"];
        sendDic = [NSMutableDictionary dictionaryWithDictionary:dictionary];
        
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"连接上接收端" message:jsonString delegate:(id<UIAlertViewDelegate>)self cancelButtonTitle:@"发送消息" otherButtonTitles:nil, nil];
        [alert show];
        
        //根据客户端给的IP，利用TCP或UDP 相互连接上就可以开始通讯了
        
    }
    return YES;
}
//没有接受到消息
-(void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error{
}

//没有发送出消息
-(void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
}

//已发送出消息
-(void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
}
//断开连接
-(void)onUdpSocketDidClose:(AsyncUdpSocket *)sock{
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
