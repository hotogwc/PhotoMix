//
//  LaunchScreenView.m
//  PhotoMix
//
//  Created by mingli.zhang on 2017/2/26.
//  Copyright © 2017年 mingli.zhang. All rights reserved.
//

#import "LaunchScreenView.h"
#import "AFHTTPSessionManager.h"
#import "MBProgressHUD.h"
#import "MBProgressHUD+SS.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "UIImageView+WebCache.h"
#import "IHealthAFNTools.h"
#import "Photo.h"
#import "SJAvatarBrowser.h"

@interface LaunchScreenView (){
    BOOL _oneImageSelected;
    BOOL _twoImageSelected;
    BOOL _threeImageSelected;
    BOOL _fourImageSelected;
    BOOL _flag;
}

#define LCD_W [UIScreen mainScreen].bounds.size.width
#define LCD_H [UIScreen mainScreen].bounds.size.height

@property (weak, nonatomic) IBOutlet UIImageView *userPhoto;

@property (weak, nonatomic) IBOutlet UIImageView *oneButtonImage;
@property (weak, nonatomic) IBOutlet UIImageView *twoButtonimage;
@property (weak, nonatomic) IBOutlet UIImageView *threeButtonImage;
@property (weak, nonatomic) IBOutlet UIImageView *fourButtonImage;

@property (weak, nonatomic) IBOutlet UIButton *oneButton;
@property (weak, nonatomic) IBOutlet UIButton *twoButton;
@property (weak, nonatomic) IBOutlet UIButton *threeButton;
@property (weak, nonatomic) IBOutlet UIButton *fourButton;

@property (strong, nonatomic) UIView *demoImageUIView;

@property (weak, nonatomic) IBOutlet UIImageView *demoImageView;

@property (strong, nonatomic) UIImage *userimage;

//约束设置
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userPhotoHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userPhotoWidth;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oneButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threeButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *twoButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fourButtonHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *takeMixVuttonWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *takeMixButtonHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *xiangceWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *xinzhaopianWidth;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fourButtonLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oneButtonLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *twoButtonLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threeButtonLeading;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oneimageLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *twoImageLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threeImageLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fourImageLeading;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *takepicMixHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *xinHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *xiangHeight;

@property (strong, nonatomic) UIImageView *enlargedImageView;

@end



@implementation LaunchScreenView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _oneImageSelected = NO;
    _twoImageSelected = NO;
    _threeImageSelected = NO;
    _fourImageSelected = YES;

    _flag = NO;
    
    self.userPhotoHeight.constant = LCD_W;
    self.userPhotoWidth.constant = LCD_W;
    
    if (LCD_H<568) {
        self.oneButtonHeight.constant = 7*LCD_W/320;
        self.threeButtonHeight.constant = 7*LCD_W/320;
        self.twoButtonHeight.constant = 7*LCD_W/320;
        self.fourButtonHeight.constant = 7*LCD_W/320;
        
        self.xiangceWidth.constant = LCD_W/2;
        self.xinzhaopianWidth.constant = LCD_W/2;
        
        self.takeMixVuttonWidth.constant = 284*LCD_W/320;
        self.takeMixButtonHeight.constant = 43*LCD_W/320;
        
        self.fourButtonLeading.constant = (LCD_W-240)/5;
        self.oneButtonLeading.constant = (LCD_W-240)/5;
        self.twoButtonLeading.constant = (LCD_W-240)/5;
        self.threeButtonLeading.constant = (LCD_W-240)/5;
        
        self.oneimageLeading.constant = 56*LCD_W/320;
        self.twoImageLeading.constant = 56*LCD_W/320;
        self.threeImageLeading.constant = 56*LCD_W/320;
        self.fourImageLeading.constant = 56*LCD_W/320;
        
        self.xinHeight.constant = 15;
        self.xiangHeight.constant = 15;
        self.takepicMixHeight.constant = 5;
    }else if(LCD_H>900){
        self.oneButtonHeight.constant = 25;
        self.threeButtonHeight.constant = 25;
        self.twoButtonHeight.constant = 25;
        self.fourButtonHeight.constant = 25;
        
        self.userPhotoHeight.constant = LCD_W*19/20;
        self.userPhotoWidth.constant = LCD_W;
        
        self.xiangceWidth.constant = LCD_W/2;
        self.xinzhaopianWidth.constant = LCD_W/2;
        
        self.takeMixVuttonWidth.constant = 284*2;
        self.takeMixButtonHeight.constant = 60;
        
        self.fourButtonLeading.constant = (LCD_W-240)/5;
        self.oneButtonLeading.constant = (LCD_W-240)/5;
        self.twoButtonLeading.constant = (LCD_W-240)/5;
        self.threeButtonLeading.constant = (LCD_W-240)/5;
        
        self.oneimageLeading.constant = 56*LCD_W/320;
        self.twoImageLeading.constant = 56*LCD_W/320;
        self.threeImageLeading.constant = 56*LCD_W/320;
        self.fourImageLeading.constant = 56*LCD_W/320;
        
        self.takepicMixHeight.constant = 16*LCD_W/320;
    }else{
        self.oneButtonHeight.constant = 17*LCD_W/320;
        self.threeButtonHeight.constant = 17*LCD_W/320;
        self.twoButtonHeight.constant = 17*LCD_W/320;
        self.fourButtonHeight.constant = 17*LCD_W/320;
        
        self.xiangceWidth.constant = LCD_W/2;
        self.xinzhaopianWidth.constant = LCD_W/2;
        
        self.takeMixVuttonWidth.constant = 284*LCD_W/320;
        self.takeMixButtonHeight.constant = 43*LCD_W/320;
        
        self.fourButtonLeading.constant = (LCD_W-240)/5;
        self.oneButtonLeading.constant = (LCD_W-240)/5;
        self.twoButtonLeading.constant = (LCD_W-240)/5;
        self.threeButtonLeading.constant = (LCD_W-240)/5;
        
        self.oneimageLeading.constant = 56*LCD_W/320;
        self.twoImageLeading.constant = 56*LCD_W/320;
        self.threeImageLeading.constant = 56*LCD_W/320;
        self.fourImageLeading.constant = 56*LCD_W/320;
        
        self.takepicMixHeight.constant = 16*LCD_W/320;
    }
    
    self.oneButtonImage.hidden = YES;
    self.twoButtonimage.hidden = YES;
    self.threeButtonImage.hidden = YES;
    self.fourButtonImage.hidden = NO;
    self.oneButton.alpha = 0.5;
    self.twoButton.alpha = 0.5;
    self.threeButton.alpha = 0.5;
    self.fourButton.alpha = 1.0;
    
    self.userimage = nil;
    self.userPhoto.image = [UIImage imageNamed:@"what.jpg"];
    
    [self.userPhoto setUserInteractionEnabled:YES];
    [self.userPhoto setMultipleTouchEnabled:YES];
    
    UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(magnifyImage)];
    [self.userPhoto addGestureRecognizer:tap];
}

- (void)magnifyImage
{
    NSLog(@"局部放大");
    [SJAvatarBrowser showImage:self.userPhoto];//调用方法
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(UIImage *) getImageFromURL:(NSString *)fileURL {
    NSLog(@"执行图片下载函数");
    UIImage * result;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
    result = [UIImage imageWithData:data];
    return result;
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
    
-(void)takePhotoOrChoosePhoto:(NSInteger)Index{
    switch (Index) {
        case 0:{
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {//camera
                UIImagePickerController *picker = [[UIImagePickerController alloc]init];
                picker.delegate = self;
                [picker setAllowsEditing:YES];
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:picker animated:YES completion:nil];
            }else{
               
            }
        }
        break;
        
        case 1:{//choose photo from device
            UIImagePickerController *m_imagePicker = [[UIImagePickerController alloc]init];
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                m_imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
                m_imagePicker.delegate = self;
                [m_imagePicker setAllowsEditing:YES];
                [self presentViewController:m_imagePicker animated:YES completion:nil];
            }else{

            }
        }
        default:
        break;
    }
}
  
- (IBAction)takePhoto:(UIButton *)sender {
    //test development——01
    [self takePhotoOrChoosePhoto:0];
}

- (IBAction)selectPhoto:(UIButton *)sender {
    //test development——02
    [self takePhotoOrChoosePhoto:1];
    //test development——03
    //test development——05
}

//处理各种手势
//http://blog.csdn.net/crayondeng/article/details/8760134

#pragma mark 放大图片
- (void)imageEnlarged: (UIImage *)image
{
    UIWindow *keyv=[[UIApplication sharedApplication] keyWindow];
    self.demoImageUIView = [[UIView alloc]init];
    
    CGRect maskViewCGRect = [[UIScreen mainScreen] bounds];
    _demoImageUIView.frame = maskViewCGRect;
    _demoImageUIView.backgroundColor = [UIColor blackColor];
    
    // 放大图片
    CGFloat imageW = image.size.width;
    CGFloat imageH = image.size.height;
    
    self.enlargedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LCD_W/2-imageW/4, LCD_H/2-imageH/4, imageW/2, imageH/2)];
    [self.enlargedImageView setImage:image];
    
    [_demoImageUIView addSubview:self.enlargedImageView];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.enlargedImageView.frame = CGRectMake(0, (LCD_H-LCD_W)/2, LCD_W, LCD_W*imageH/imageW);
    } completion:^(BOOL finished) {
        
    }];
    
    // 添加点击手势 点击后取消缩放
    UITapGestureRecognizer *SingleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageReduced:)];
    SingleTapGesture.numberOfTapsRequired = 1;//tap次数
    [_demoImageUIView addGestureRecognizer:SingleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [_demoImageUIView addGestureRecognizer:doubleTapGesture];
    [SingleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [_demoImageUIView addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    [_demoImageUIView addGestureRecognizer:panGesture];
    
    [keyv addSubview:_demoImageUIView];
}

// 处理拖拉手势
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = self.enlargedImageView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
}

//- (void)scaleImage:(UIPinchGestureRecognizer *)recognizer
//{
//    if([recognizer state] == UIGestureRecognizerStateEnded) {
//        // 如果Pinch 手势结束，重置 previousScale 为 1.0
//        self.previousScale = 1.0;
//        return;
//    }
//    CGFloat newScale = [recognizer scale]-self.previousScale +1.0;
//    CGAffineTransform currentTransformation = self.productImageView.transform;
//    // CGAffineTransformScale(currentTransformation, 1, 1) 变换保持原大小
//    CGAffineTransform newTransform = CGAffineTransformScale(currentTransformation, newScale, newScale);
//    // perform the new transform
//    self.productImageView.transform = newTransform;
//    self.previousScale = [recognizer scale];
//}

// 处理捏合缩放手势
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = self.enlargedImageView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
}

//双击实现放大和缩小一倍
- (void) handleDoubleTapFrom:(UIGestureRecognizer *)recoginzer {
    NSLog(@"双击！！！");
    if(!_flag){
        _flag = YES;
        [UIView setAnimationDuration:3];
        [self.enlargedImageView setFrame:CGRectMake(LCD_W/2 - LCD_W, LCD_H/2 - LCD_H, 2 * LCD_W, 2 * LCD_H)];
        [UIView commitAnimations];
    }else{
        _flag = NO;
        [UIView setAnimationDuration:3];
        [self.enlargedImageView setFrame:CGRectMake(0, (LCD_H-LCD_W)/2, LCD_W, LCD_W)];
        [UIView commitAnimations];
    }
    
}

#pragma mark 缩小图片
- (void)imageReduced: (UIGestureRecognizer*)recoginzer
{
    [_demoImageUIView removeFromSuperview];
    self.demoImageUIView = nil;
}

- (IBAction)selectDemoOne:(UIButton *)sender {
    if(!_oneImageSelected){
        [self imageEnlarged:[UIImage imageNamed:@"1"]];
        
        _oneImageSelected = YES;
        _twoImageSelected = NO;
        _threeImageSelected = NO;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = NO;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 1.0;
        self.twoButton.alpha = 0.5;
        self.threeButton.alpha = 0.5;
        self.fourButton.alpha = 0.5;
    }else{
        _oneImageSelected = NO;
        _twoImageSelected = NO;
        _threeImageSelected = NO;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 1.0;
        self.twoButton.alpha = 1.0;
        self.threeButton.alpha = 1.0;
        self.fourButton.alpha = 1.0;
    }
}
- (IBAction)selectDemoTwo:(UIButton *)sender {
    if(!_twoImageSelected){
        [self imageEnlarged:[UIImage imageNamed:@"2"]];
        _oneImageSelected = NO;
        _twoImageSelected = YES;
        _threeImageSelected = NO;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = NO;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 0.5;
        self.twoButton.alpha = 1.0;
        self.threeButton.alpha = 0.5;
        self.fourButton.alpha = 0.5;
    }else{
        _oneImageSelected = NO;
        _twoImageSelected = NO;
        _threeImageSelected = NO;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 1.0;
        self.twoButton.alpha = 1.0;
        self.threeButton.alpha = 1.0;
        self.fourButton.alpha = 1.0;
    }
}
- (IBAction)selectDemoThree:(UIButton *)sender {
    if(!_threeImageSelected){
        [self imageEnlarged:[UIImage imageNamed:@"3"]];
        _oneImageSelected = NO;
        _twoImageSelected = NO;
        _threeImageSelected = YES;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = NO;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 0.5;
        self.twoButton.alpha = 0.5;
        self.threeButton.alpha = 1.0;
        self.fourButton.alpha = 0.5;
    }else{
        _oneImageSelected = NO;
        _twoImageSelected = NO;
        _threeImageSelected = NO;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 1.0;
        self.twoButton.alpha = 1.0;
        self.threeButton.alpha = 1.0;
        self.fourButton.alpha = 1.0;
    }
}

- (IBAction)selectDemoFour:(UIButton *)sender {
    if(!_fourImageSelected){
        [self imageEnlarged:[UIImage imageNamed:@"4"]];
        _oneImageSelected = NO;
        _twoImageSelected = NO;
        _threeImageSelected = NO;
        _fourImageSelected = YES;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = NO;
        self.oneButton.alpha = 0.5;
        self.twoButton.alpha = 0.5;
        self.threeButton.alpha = 0.5;
        self.fourButton.alpha = 1.0;
    }else{
        _oneImageSelected = NO;
        _twoImageSelected = NO;
        _threeImageSelected = NO;
        _fourImageSelected = NO;
        
        self.oneButtonImage.hidden = YES;
        self.twoButtonimage.hidden = YES;
        self.threeButtonImage.hidden = YES;
        self.fourButtonImage.hidden = YES;
        self.oneButton.alpha = 1.0;
        self.twoButton.alpha = 1.0;
        self.threeButton.alpha = 1.0;
        self.fourButton.alpha = 1.0;
    }
}

- (void)loadImageFinished:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

- (IBAction)mixPhotoButton:(UIButton *)sender {
    if(self.userimage == nil){
        NSLog(@"请先添加照片...");
    }else{
        if(!(_oneImageSelected || _twoImageSelected || _threeImageSelected || _fourImageSelected)){
            NSLog(@"未选择模板...");
        }else{
            
            [MBProgressHUD showSuccess:@"正在转换..."];
            
            NSData* pictureData = UIImageJPEGRepresentation([Photo scaleImage:self.userimage toWidth:800 toHeight:800], 1);
            //进行图片压缩从0.0到1.0（0.0表示最大压缩，质量最低);
            NSLog(@"图片大小：%zdkB", pictureData.length/1024);
            NSString* pictureDataString = [pictureData base64Encoding];
            NSNumber * style = _oneImageSelected?@2:(_twoImageSelected?@3:(_threeImageSelected?@4:@1));
            NSDictionary *params = @{
                                     @"image" : pictureDataString,
                                     @"style" : style
                                     };
            
            __weak __typeof(self)weakSelf = self;
            //NSString *url = @"http://AlgTest.mi-ae.net/getPic";
            NSString *url = @"http://120.92.88.1:80/getPic";
            
            [IHealthAFNTools postWithUrl:url params:params isParseJsonData:YES success:^(id response) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                if([[NSString stringWithFormat:@"%@", response[@"code"]] isEqualToString:@"0"]){
                    
                    [MBProgressHUD hideHUD];
                    
                    UIImage *image = [Photo string2Image:response[@"pic"]];
                    
                    [self loadImageFinished:image];
                    
                    //UIImage *image = [self getImageFromURL:[NSString stringWithFormat:@"%@", response[@"pic"]]];
                    strongSelf.userPhoto.image = image;
                }
                
            } fail:^(NSError *error) {
                [MBProgressHUD hideHUD];
            }];
        }
    }
}

#pragma mark - PhotoPicker Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (image!=nil) {
        //UIImage *_image = [Photo scaleImage:image toWidth:342 toHeight:342];
        self.userPhoto.image = image;
        
        
        
        self.userimage = image;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}
    
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;//只支持这一个方向(正常的方向)
}

@end
