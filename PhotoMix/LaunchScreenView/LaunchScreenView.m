//
//  LaunchScreenView.m
//  PhotoMix
//
//  Created by mingli.zhang on 2017/2/26.
//  Copyright © 2017年 mingli.zhang. All rights reserved.
//

#import "LaunchScreenView.h"
#import "Photo.h"

@interface LaunchScreenView ()
    
@property (weak, nonatomic) IBOutlet UIImageView *userPhoto;

@end

@implementation LaunchScreenView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
    [self takePhotoOrChoosePhoto:0];
}

- (IBAction)selectPhoto:(UIButton *)sender {
    [self takePhotoOrChoosePhoto:1];
}

#pragma mark - PhotoPicker Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (image!=nil) {
        self.userPhoto.image = [Photo scaleImage:image toWidth:375 toHeight:400];
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

@end
