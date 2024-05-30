//
//  ViewController.m
//  JumpToGPSDemo
//
//  Created by 1084-Wangcl-Mac on 2024/5/28.
//  Copyright © 2024 Charles2021. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import "WWLocationConverter.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = 20202203;
    button.frame = CGRectMake((self.view.frame.size.width - 200) / 2, 100, 200, 40);
    button.titleLabel.font = [UIFont systemFontOfSize:13];
    [button setTitle:@"开始导航" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(gpsAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)gpsAction:(UIButton *)button {
    CLLocationDegrees latitude = 31.178513;
    CLLocationDegrees longitude = 121.494612;
    CLLocationCoordinate2D endLocation = CLLocationCoordinate2DMake(latitude, longitude);
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"请选择导航" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *titles = @[@"百度地图", @"腾讯地图", @"高德地图", @"苹果地图"];
    for (int i = 0; i < titles.count; i++) {
        NSString *title = titles[i];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
           [self navThirdMapWithLocation:endLocation andTitle:title];
        }];
        [alertVC addAction:action];
    }

    UIAlertAction *cancleAct = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertVC addAction:cancleAct];
    [self presentViewController:alertVC animated:YES completion:nil];
}
 
-(void)navThirdMapWithLocation:(CLLocationCoordinate2D)endLocation andTitle:(NSString *)andTitle {
    /**
     <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>iosamap</string>
        <string>baidumap</string>
        <string>qqmap</string>
    </array>
    * 1、地球坐标 ：（ 代号：GPS、WGS84 ）--- 有W就是世界通用的
    *  苹果的  CLLocationManager 获取的坐标
    * 2、火星坐标： （代号：GCJ-02）--- * G国家 C测绘 J局 02年测绘的*
    *  高德地图、腾讯地图、阿里云地图、灵图51地图
    *  现在苹果系统自带的地图使用的是高德地图，所以苹果地带的地图应用，用的是GCJ-02的坐标系统。但是代码中CLLocationManager获取到的是WGS84坐标系的坐标
    * 3、其他坐标 ：百度坐标系统 （代号：BD-09）
    *  使用 BD-09 坐标系统的产品有: 百度地图
    */
    NSString *destination = @"世博大道";
    NSString *mapType = andTitle;
    NSString *openUrl = @"";
    NSString *downloadUrl = @"";
    NSString *routeUrl = @"";
    //将h5传来的WGS84转GCJ-02坐标系，再在腾讯，高德，苹果地图上使用
    CLLocationCoordinate2D coord = [WWLocationConverter wgs84ToGcj02:endLocation];
    if ([@"百度地图" isEqual:mapType]) {
        //将h5传来的WGS84转BD09坐标系，再在百度地图上使用
        coord = [WWLocationConverter wgs84ToBd09:endLocation];
        openUrl = @"baidumap://";
        routeUrl = [NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=bd09ll", coord.latitude, coord.longitude];
        downloadUrl = @"itms-apps://itunes.apple.com/cn/app/id452186370?mt=8";
    } else if ([@"腾讯地图" isEqual:mapType]) {
        openUrl = @"qqmap://";
        routeUrl = [NSString stringWithFormat:@"qqmap://map/routeplan?from=我的位置&type=drive&to=%@&tocoord=%f,%f&coord_type=1&referer={ios.blackfish.XHY}", destination, coord.latitude, coord.longitude];
        downloadUrl = @"itms-apps://itunes.apple.com/app/id481623196?mt=8";
    } else if ([@"高德地图" isEqual:mapType]) {
        openUrl = @"iosamap://";
        routeUrl = [NSString stringWithFormat:@"iosamap://path?sourceApplication=ios.blackfish.XHY&dlat=%f&dlon=%f&dname=%@&style=2", coord.latitude, coord.longitude, destination];
        downloadUrl = @"itms-apps://itunes.apple.com/app/id461703208?mt=8";
    } else if ([@"苹果地图" isEqual:mapType]) {
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *tolocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:coord addressDictionary:nil]];
        tolocation.name = destination;
        [MKMapItem openMapsWithItems:@[currentLocation,tolocation] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey:[NSNumber numberWithBool:YES]}];
        return;
    }
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:openUrl]]) {
        NSString *urlString = [routeUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    } else {
        UIAlertController *altVC = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"你尚未安装%@，是否立刻下载?", mapType] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //跳转到地图App下载
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:downloadUrl] options:@{} completionHandler:nil];
        }];
        [altVC addAction:okAction];
        UIAlertAction *canceAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [altVC addAction:canceAction];
        [self presentViewController:altVC animated:YES completion:nil];
    }
}

@end
