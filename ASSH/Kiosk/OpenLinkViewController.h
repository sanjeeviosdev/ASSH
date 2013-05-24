//
//  OpenLinkViewController.h
//  Hand care
//
//  Created by Sanjeev Jha on 19/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenLinkViewController : UIViewController
@property(nonatomic,weak) IBOutlet UIWebView *webView;
@property(nonatomic,weak) NSString *urlStr;

@end
