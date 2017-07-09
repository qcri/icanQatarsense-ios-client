//
//  HelpViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "HelpViewController.h"
#import "AppConfig.h"
#import "SWRevealViewController.h"
#import "HelperClass.h"


@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Set view's background color
//    self.view.backgroundColor = [UIColor colorWithRed:40/255.0f green:40/255.0f blue:40/255.0f alpha:1];
    
    //Set appropriate background image as per screen size
    [self setBackgroundImage];
    
    //Make menu button at top left working
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController)
    {
        [self.menuButton setTarget:revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    //Set title view of navigation item
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,40,320,40)];
    titleLabel.textAlignment = NSTextAlignmentRight;
    titleLabel.font = [UIFont fontWithName:@"Prototype" size:17.0f];
    titleLabel.textColor = [UIColor colorWithRed:247/255.0f green:210/255.0f blue:0 alpha:1];
    titleLabel.text = self.title;
    self.navigationItem.titleView = titleLabel;
    
    //Make navigation bar transparent
    [self presentTransparentNavigationBar];
    
    //Show content on webView
    NSString * content = [HelperClass htmlFromBodyString:kHelpContent textFont:[UIFont fontWithName:@"Prototype" size:16.0f] textColor:[UIColor colorWithRed:0 green:70/255.0f blue:0 alpha:1]];
    [self.webView loadHTMLString:content baseURL:nil];
}


- (void)presentTransparentNavigationBar
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
}



/*
 * @desc - Sets appropriate background image as per screen size
 */
-(void)setBackgroundImage
{
    if(kScreenHeight == 568.0f)
    {
        self.backgroundImageView.image = [UIImage imageNamed:@"Background-568h@2x.png"];
    }
    else if(kScreenHeight == 667.0f)
    {
        self.backgroundImageView.image = [UIImage imageNamed:@"Background-667h@2x.png"];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
