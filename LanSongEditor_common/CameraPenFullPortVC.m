//
//  CameraPenFullPortVC.m
//  LanSongEditor_all
//
//  Created by sno on 2017/9/21.
//  Copyright © 2017年 sno. All rights reserved.
//

#import "CameraPenFullPortVC.h"
#import "LanSongUtils.h"
#import "BlazeiceDooleView.h"
#import "FilterTpyeList.h"
#import "YXLabel.h"


// 定义录制的时间,这里是15秒
#define  CAMERAPEN_RECORD_MAX_TIME 15

@interface CameraPenFullPortVC ()
{
    
    NSString *dstPath;
    
    Pen *operationPen;  //当前操作的图层
    
    
    FilterTpyeList *filterListVC;
    BOOL  isSelectFilter;
    
    UISlider *filterSlider;
    DrawPadCamera *drawPad;
    CameraPen  *cameraPen;
    DrawPadView *filterView;
    VideoPen *videoPen;
    BitmapPen *bmpPen;
    YXLabel *label; //test
    
    BOOL isPaused;
    CGFloat padWidth;
    CGFloat padHeight;
}
@end

@implementation CameraPenFullPortVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor whiteColor];
    /*
     step1:第一步: 创建容器(尺寸,码率,编码后的目标文件路径,增加一个预览view)
     */
    padWidth=540;
    padHeight=960;
    drawPad=[[DrawPadCamera alloc] initWithPadSize:CGSizeMake(padWidth, padHeight) isFront:YES];
    /*
     step2:增加一个view,用来显示
     */
    filterView=[[DrawPadView alloc] initWithFrame:self.view.frame];
    [self.view addSubview: filterView];
    [drawPad setDrawPadDisplay:filterView];
    

    //增加一个图片图层,放到中间靠右侧.
    UIImage *image=[UIImage imageNamed:@"small"];
    bmpPen=    [drawPad addBitmapPen:image];
    bmpPen.positionX=bmpPen.drawPadSize.width-bmpPen.penSize.width/2;
    
    /*
     step3:第三步: 开始预览
     */
    [drawPad startPreview];
    
   //进度显示.
    __weak typeof(self) weakSelf = self;
    [drawPad setOnProgressBlock:^(CGFloat currentPts) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.labProgress.text=[NSString stringWithFormat:@"当前进度 %f",currentPts];
        });
    }];
    
    
    cameraPen=drawPad.cameraPen;
    //初始化其他UI界面.
    [self initView];
    
    filterListVC=[[FilterTpyeList alloc] initWithNibName:nil bundle:nil];
    filterListVC.filterSlider=filterSlider;
    filterListVC.filterPen=drawPad.cameraPen;
}
-(void)doButtonClicked:(UIView *)sender
{
    switch (sender.tag) {
        case 101 :  //filter
            isSelectFilter=YES;
            [self.navigationController pushViewController:filterListVC animated:YES];
            break;
        case  102:  //btnStart;
            if(drawPad.isRecording==NO){
                dstPath=[SDKFileUtil genTmpMp4Path];  //这里创建一个路径.
                [drawPad startRecordWithPath:dstPath];
            }
             [label startAnimation];
            break;
        case  103:  //btnOK;
            [drawPad exchangePenPosition:videoPen second:cameraPen];
            if(drawPad.isRecording){
                [drawPad stopRecord];
                [LanSongUtils startVideoPlayerVC:self.navigationController dstPath:dstPath];
            }
            break;
        case  104:  //btnSelect;
            if(cameraPen!=nil){
                [cameraPen rotateCamera];
            }
            break;
        default:
            break;
    }
}
-(void)viewDidAppear:(BOOL)animated
{
    isSelectFilter=NO;
}
-(void)viewDidDisappear:(BOOL)animated
{
    
   
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


-(void)showIsPlayDialog
{
    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:@"提示" message:@"视频已经处理完毕,是否需要预览" delegate:self cancelButtonTitle:@"预览" otherButtonTitles:@"返回", nil];
    [alertView show];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        [LanSongUtils startVideoPlayerVC:self.navigationController dstPath:dstPath];
    }else {  //返回
        
    }
}
-(void)dealloc
{
    operationPen=nil;
    drawPad=nil;
    filterListVC=nil;
    filterView=nil;
    
    
    [SDKFileUtil deleteFile:dstPath];
    dstPath=nil;
    
    NSLog(@"CameraPenDemoVC  dealloc");
}
/**
 滑动 效果调节后的相应
 
 */
- (void)slideChanged:(UISlider*)sender
{
    switch (sender.tag) {
        case 101:
            [filterListVC updateFilterFromSlider:sender];
            break;
        default:
            break;
    }
}
-(void)initView
{
    CGSize size=self.view.frame.size;
    CGFloat padding=size.height*0.01;
    
    CGFloat  layHeight=self.view.frame.size.height*3/4;
    
    _labProgress=[[UILabel alloc] init];
    _labProgress.textColor=[UIColor redColor];
    
    [self.view addSubview:_labProgress];
    
    [_labProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top).offset(layHeight);
        make.centerX.mas_equalTo(filterView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(size.width, 40));
    }];
    
    filterSlider=[self createSlide:_labProgress min:0.0f max:1.0f value:0.5f tag:101 labText:@"效果调节 "];
    
    UIButton *btnFilter=[[UIButton alloc] init];
    [btnFilter setTitle:@"滤镜" forState:UIControlStateNormal];
    [btnFilter setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//    btnFilter.backgroundColor=[UIColor whiteColor];
    btnFilter.tag=101;
    
    
    UIButton *btnStart=[[UIButton alloc] init];
    [btnStart setTitle:@"开始" forState:UIControlStateNormal];
    [btnStart setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    btnStart.tag=102;
    
    UIButton *btnOK=[[UIButton alloc] init];
    [btnOK setTitle:@"停止" forState:UIControlStateNormal];
    [btnOK setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btnOK setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    btnOK.tag=103;
    
    UIButton *btnSelect=[[UIButton alloc] init];
    [btnSelect setTitle:@"前置" forState:UIControlStateNormal];
    [btnSelect setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    btnSelect.tag=104;
    
    
    [btnStart addTarget:self action:@selector(doButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [btnOK addTarget:self action:@selector(doButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [btnFilter addTarget:self action:@selector(doButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [btnSelect addTarget:self action:@selector(doButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:btnFilter];
    [self.view addSubview:btnStart];
    [self.view addSubview:btnOK];
    [self.view addSubview:btnSelect];
    
    CGFloat btnWH=50;
    [btnStart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(filterSlider.mas_bottom).offset(padding);
        make.left.mas_equalTo(filterView.mas_left).offset(padding);
        make.size.mas_equalTo(CGSizeMake(btnWH, btnWH));
    }];
    [btnOK mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(filterSlider.mas_bottom).offset(padding);
        make.left.mas_equalTo(btnStart.mas_right).offset(padding);
        make.size.mas_equalTo(CGSizeMake(btnWH, btnWH));
    }];
    
    [btnFilter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(filterSlider.mas_bottom).offset(padding);
        make.left.mas_equalTo(btnOK.mas_right).offset(padding);
        make.size.mas_equalTo(CGSizeMake(btnWH, btnWH));
    }];
    
    [btnSelect mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(filterSlider.mas_bottom).offset(padding);
        make.left.mas_equalTo(btnFilter.mas_right).offset(padding);
        make.size.mas_equalTo(CGSizeMake(btnWH, btnWH));
    }];
}
/**
 初始化一个slide 返回这个UISlider对象
 */
-(UISlider *)createSlide:(UIView *)topView  min:(CGFloat)min max:(CGFloat)max  value:(CGFloat)value tag:(int)tag labText:(NSString *)text;
{
    UILabel *labPos=[[UILabel alloc] init];
    labPos.text=text;
    
    UISlider *slideFilter=[[UISlider alloc] init];
    
    slideFilter.maximumValue=max;
    slideFilter.minimumValue=min;
    slideFilter.value=value;
    slideFilter.continuous = YES;
    slideFilter.tag=tag;
    
    [slideFilter addTarget:self action:@selector(slideChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    CGSize size=self.view.frame.size;
    CGFloat padding=size.height*0.01;
    
    [self.view addSubview:labPos];
    [self.view addSubview:slideFilter];
    
    
    [labPos mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(topView.mas_bottom).offset(padding);
        make.left.mas_equalTo(self.view.mas_left);
        make.size.mas_equalTo(CGSizeMake(100, 40));
    }];
    
    [slideFilter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(labPos.mas_centerY);
        make.left.mas_equalTo(labPos.mas_right).offset(padding);
        make.right.mas_equalTo(self.view.mas_right).offset(-padding);
    }];
    return slideFilter;
}

@end

