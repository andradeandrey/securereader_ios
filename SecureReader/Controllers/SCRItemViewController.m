//
//  SCRItemViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-24.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemViewController.h"
#import "SCRItemPageViewController.h"
#import "SCRItem.h"

@interface SCRItemViewController ()
- (void)updateBarButtonItems:(CGFloat)alpha;
@property SCRFeedViewController *itemDataSource;
@property NSIndexPath *currentItemIndex;
@property CGFloat previousScrollViewYOffset;
@property CGFloat yStart;
@property (weak, nonatomic) IBOutlet UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *container;
@end

@implementation SCRItemViewController

@synthesize pageViewController;
@synthesize itemDataSource;
@synthesize currentItemIndex;

- (void)viewDidLoad {
    [super viewDidLoad];
    pageViewController = [[self childViewControllers] objectAtIndex:0];
    
    self.yStart = self.view.frame.size.height;
    
    pageViewController.delegate = self;
    if (itemDataSource != nil && currentItemIndex != nil)
    {
        [pageViewController setDataSource:self];
        
        SCRItem *item = [itemDataSource itemForIndexPath:currentItemIndex];
        SCRItemPageViewController *initialViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"fullScreenItemView"];
        [initialViewController setItem:item];
        [initialViewController setItemIndexPath:currentItemIndex];
        initialViewController.scrollView.delegate = self;
        NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
        [pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}

- (UIViewController *)viewControllerForIndexPath:(NSIndexPath *)indexPath
{
    SCRItem *item = [itemDataSource itemForIndexPath:indexPath];
    if (item != nil)
    {
        SCRItemPageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"fullScreenItemView"];
        [vc setItem:item];
        [vc setItemIndexPath:indexPath];
        vc.scrollView.delegate = self;
        return vc;
    }
    return nil;
}

#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    if (pendingViewControllers != nil && pendingViewControllers.count > 0)
    {
        NSObject *o = [pendingViewControllers objectAtIndex:0];
        if ([o isKindOfClass:[SCRItemPageViewController class]])
        {
            UIScrollView *scrollView = ((SCRItemPageViewController *)o).scrollView;
            if (scrollView != nil)
                [scrollView setContentOffset:
                 CGPointMake(0, -scrollView.contentInset.top) animated:YES];
        }
    }
}

- (void)pageViewController:(UIPageViewController *)pvc didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    //[self animateNavBarTo:0];

//    if (pvc.viewControllers != nil && pvc.viewControllers.count > 0)
//    {
//        NSObject *o = [pvc.viewControllers objectAtIndex:0];
//        if ([o isKindOfClass:[SCRItemPageViewController class]])
//        {
//            UIScrollView *scrollView = ((SCRItemPageViewController *)o).scrollView;
//            if (scrollView != nil)
//                scrollView.delegate = self;
//        }
//    }
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[SCRItemPageViewController class]])
    {
        NSIndexPath *indexPath = [(SCRItemPageViewController *)viewController itemIndexPath];
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:(indexPath.row - 1)
                                                  inSection:indexPath.section];
        return [self viewControllerForIndexPath:newPath];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[SCRItemPageViewController class]])
    {
        NSIndexPath *indexPath = [(SCRItemPageViewController *)viewController itemIndexPath];
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:(indexPath.row + 1)
                                                  inSection:indexPath.section];
        return [self viewControllerForIndexPath:newPath];
    }
    return nil;
}


#pragma mark - Scroll handling

- (void)stoppedScrolling
{
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        [self animateNavBarTo:-(frame.size.height - 21)];
    }
}

- (void)updateBarButtonItems:(CGFloat)alpha
{
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)animateNavBarTo:(CGFloat)y
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateBarButtonItems:alpha];
        frame = self.view.frame;
        frame.origin.y = y + self.navigationController.navigationBar.frame.size.height;
        frame.size.height = self.yStart - frame.origin.y;
        [self.view setFrame:frame];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect frame = self.navigationController.navigationBar.frame;
    CGFloat size = frame.size.height - 21;
    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = scrollOffset - self.previousScrollViewYOffset;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;
    
    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
    }
    
    CGFloat y = frame.origin.y;
    [self.navigationController.navigationBar setFrame:frame];
    frame = self.view.frame;
    frame.origin.y = y + self.navigationController.navigationBar.frame.size.height;
    frame.size.height = self.yStart - frame.origin.y;
    [self.view setFrame:frame];
    [self updateBarButtonItems:(1 - framePercentageHidden)];
    self.previousScrollViewYOffset = scrollOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self stoppedScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self stoppedScrolling];
    }
}


#pragma mark - Data

- (void) setDataView:(SCRFeedViewController *)feedView withStartAt:(NSIndexPath *)indexPath
{
    self.itemDataSource = feedView;
    self.currentItemIndex = indexPath;
}



@end
