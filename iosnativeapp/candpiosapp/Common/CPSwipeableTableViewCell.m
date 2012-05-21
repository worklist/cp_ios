//
//  CPSwipeableTableViewCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/16/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

// --------------------------
// credit where credit is due
// --------------------------
// much of this code is taken from ZKRevealingTableViewCell
// found at https://github.com/alexzielenski/ZKRevealingTableViewCell

// some modfications have been made to have a swipe to the right be
// the quick action, while a left swipe reveals the view with all actions

#import "CPSwipeableTableViewCell.h"
#import <objc/runtime.h>

# define BUTTON_LEFT_MARGIN 20
# define PADDING_TO_CONTAINER_IMAGE 16
# define QUICK_ACTION_MARGIN 83

@interface CPSwipeableTableViewCell()
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, readonly, assign) CGFloat originalCenter;
@property (nonatomic, assign) CGFloat initialTouchPositionX;
@property (nonatomic, assign) CGFloat initialHorizontalCenter;
@property (nonatomic, assign) CPSwipeableTableViewCellDirection lastDirection;
@property (nonatomic, assign) CPSwipeableTableViewCellDirection currentDirection;
@property (nonatomic, strong) NSMutableArray *secretButtons;
@property (nonatomic, strong) NSMutableArray *secretImageViews;

- (BOOL)shouldDragLeft;
- (BOOL)shouldDragRight;
- (BOOL)shouldReveal;

@end

@implementation CPSwipeableTableViewCell

// public attrs
@synthesize delegate = _delegate;
@synthesize hiddenView = _hiddenView;
@synthesize shouldBounce = _shouldBounce;
@synthesize leftStyle = _leftStyle;
@synthesize rightStyle = _rightStyle;
@synthesize secretIcons = _secretIcons;

// private attrs
@synthesize panRecognizer = _panRecognizer;
@synthesize initialTouchPositionX = _initialTouchPositionX;
@synthesize initialHorizontalCenter = _initialHorizontalCenter;
@synthesize lastDirection = _lastDirection;
@synthesize currentDirection = _currentDirection;
@synthesize secretButtons = _secretButtons;
@synthesize secretImageViews = _secretImageViews;
@dynamic revealing;


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // bounce by default
    self.shouldBounce = YES;

    // go both ways by default (haha)
    self.leftStyle = CPSwipeableTableViewCellSwipeStyleFull;
    self.rightStyle = CPSwipeableTableViewCellSwipeStyleFull;
    
    // setup our pan gesture recognizer
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    self.panRecognizer.delegate = self;
    
    [self addGestureRecognizer:self.panRecognizer];
    
    // setup the background view
    self.hiddenView = [[UIView alloc] initWithFrame:self.contentView.frame];
    self.hiddenView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-dark"]];
    
    // setup a CGRect that we'll manipulate to add some subviews
    CGRect changeFrame = self.hiddenView.frame;
    
    // make the UIImageView be as wide as the cell but only 15pts high
    changeFrame.size.height = 15;
    
    // setup the UIImage that is our gradient
    UIImage *embossedGradient = [[UIImage imageNamed:@"cell-shadow-harsh"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    // alloc-init a UIImageView for the top gradient
    UIImageView *topGradient = [[UIImageView alloc] initWithFrame:changeFrame];
    // give it the gradient image
    topGradient.image = embossedGradient;
    
    // change the frame of the bottom gradient so it's 15 pts high
    changeFrame.origin.y = self.hiddenView.frame.size.height - 15;
    
    // alloc-init a UIImageView for the bottom gradient
    UIImageView *bottomGradient = [[UIImageView alloc] initWithFrame:changeFrame];
    // give it the gradient image
    bottomGradient.image = embossedGradient;
    
    // rotate the bottom one so it's the other way
    bottomGradient.layer.transform = CATransform3DMakeRotation(M_PI, 1.0f, 0.0f, 0.0f);
    
    bottomGradient.frame = changeFrame;
    
    // add the top gradients to the hidden view
    [self.hiddenView addSubview:topGradient];
    [self.hiddenView addSubview:bottomGradient];
    
    // add a line to the buttom of the view to maintain separation when revealing hidden view
    
    changeFrame.size.height = 1;
    changeFrame.origin.y = self.hiddenView.frame.size.height - 1;
    
    // alloc-init the bottom line and match the color with the line color from the user list table
    UIView *bottomLine = [[UIView alloc] initWithFrame:changeFrame];
    bottomLine.backgroundColor = [UIColor colorWithR:68 G:68 B:68 A:1];
    
    // add the bottom line to the hidden view
    [self.hiddenView addSubview:bottomLine];
    
    // make sure the hiddenView clips its subviews to its bounds
    self.hiddenView.clipsToBounds = YES;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self addSubview:self.hiddenView];
	[self addSubview:self.contentView];
	self.hiddenView.frame = self.contentView.frame;
}

- (NSMutableArray *)secretButtons
{
    // lazily instantiate an NSMutableArary for the action buttons
    if (!_secretButtons) {
        _secretButtons = [NSMutableArray array];
    }
    return _secretButtons;
}

- (NSMutableArray *)secretImageViews
{
    // lazily instantiate an NSMutableArray for the secret images
    if (!_secretImageViews) {
        _secretImageViews = [NSMutableArray array];
    }
    return _secretImageViews;
}

- (void)setSecretIcons:(NSArray *)secretIcons
{    
    // when our secret icons array gets set we want to add the icons to the background view
    
    // let's make sure first we remove all of the buttons and images that might currently be there
    
    for (UIButton *oldButton in self.secretButtons) {
        [oldButton removeFromSuperview];
    }
    
    // clear the array of secretButtons
    [self.secretButtons removeAllObjects];
    
    for (UIImageView *oldImageView in self.secretImageViews) {
        [oldImageView removeFromSuperview];
    }
    
    // clear the array of secretImageViews
    [self.secretImageViews removeAllObjects];
    
    if (secretIcons.count > 0) {
        UIImage *containerImage = [UIImage imageNamed:@"action-button-container"];
        
        // start at 4 points in (it needs
        CGFloat originX = BUTTON_LEFT_MARGIN - PADDING_TO_CONTAINER_IMAGE;
        
        // cycle through the images in the secretIcons array
        for (UIImage *actionImage in secretIcons) {
            UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
            
            // set the image for the action button to the container image
            [actionButton setBackgroundImage:containerImage forState:UIControlStateNormal];
            
            // change the frame of the action button
            CGRect containerFrame = CGRectMake(originX, -containerImage.size.height, containerImage.size.width, containerImage.size.height);
            actionButton.frame = containerFrame;
            
            // add the action button to the hiddenView
            [self.hiddenView addSubview:actionButton];
            
            // add this action button to our array of action buttons so we can grab it later
            [self.secretButtons addObject:actionButton];
            
            // alloc-init an imageView to hold the icon
            UIImageView *secretImageView = [[UIImageView alloc] initWithImage:actionImage];
            
            // move the secretImageView to the right spot
            CGRect iconHider = secretImageView.frame;
            iconHider.origin.x = originX;
            iconHider.origin.y = self.contentView.frame.size.height;
            secretImageView.frame = iconHider;
            
            // add the secretImageView to the hiddenView
            [self.hiddenView addSubview:secretImageView];
            
            // add the secret icon to our array of secret icons to grab it later
            [self.secretImageViews addObject:secretImageView];
            
            // add some padding for the next button
            originX += 20;
        }
    }

    // set the instance variable to the passed array
    _secretIcons = secretIcons;
}

static char BOOLRevealing;

- (BOOL)isRevealing
{
	return [(NSNumber *)objc_getAssociatedObject(self, &BOOLRevealing) boolValue];
}

- (void)setRevealing:(BOOL)revealing
{
	// Don't change the value if its already that value.
	// Reveal unless the delegate says no
	if (revealing == self.revealing || 
		(revealing && self.shouldReveal))
		return;
	
	[self _setRevealing:revealing];
	
	if (self.isRevealing)
		[self performActionInDirection:(self.isRevealing) ? self.currentDirection : self.lastDirection];
	else
		[self slideInContentViewFromDirection:(self.isRevealing) ? self.currentDirection : self.lastDirection offsetMultiplier:self.bounceMultiplier];
}

- (void)_setRevealing:(BOOL)revealing
{
    [self willChangeValueForKey:@"isRevealing"];
	objc_setAssociatedObject(self, &BOOLRevealing, [NSNumber numberWithBool:revealing], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:@"isRevealing"];
	
	if (self.isRevealing && [self.delegate respondsToSelector:@selector(cellDidReveal:)])
		[self.delegate cellDidReveal:self];
}

- (BOOL)shouldReveal
{
	// Conditions are checked in order
	return (![self.delegate respondsToSelector:@selector(cellShouldReveal:)] || [self.delegate cellShouldReveal:self]);
}

#pragma mark - Handing Touch

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation           = [recognizer translationInView:self];
	CGPoint currentTouchPoint     = [recognizer locationInView:self];
	CGPoint velocity              = [recognizer velocityInView:self];
	
    CGFloat originalCenter        = self.originalCenter;
    CGFloat currentTouchPositionX = currentTouchPoint.x;
    CGFloat panAmount             = self.initialTouchPositionX - currentTouchPositionX;
    CGFloat newCenterPosition     = self.initialHorizontalCenter - panAmount;
    CGFloat centerX               = self.contentView.center.x;
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		
		// Set a baseline for the panning
		self.initialTouchPositionX = currentTouchPositionX;
		self.initialHorizontalCenter = self.contentView.center.x;
		
		if ([self.delegate respondsToSelector:@selector(cellDidBeginPan:)])
			[self.delegate cellDidBeginPan:self];
		
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		
		// If the pan amount is negative, then the last direction is left, and vice versa.
		if (newCenterPosition - centerX < 0)
			self.lastDirection = CPSwipeableTableViewCellDirectionLeft;
		else
			self.lastDirection = CPSwipeableTableViewCellDirectionRight;
        
		// Don't let you drag past a certain point depending on direction
		if ((newCenterPosition < originalCenter && ![self shouldDragLeft]) || (newCenterPosition > originalCenter && ![self shouldDragRight])) {
            newCenterPosition = originalCenter;
        }
			
        
        // if our style is quick action then don't go past the defined margin
        if (newCenterPosition > originalCenter + QUICK_ACTION_MARGIN && self.rightStyle == CPSwipeableTableViewCellSwipeStyleQuickAction) {
            newCenterPosition = originalCenter + QUICK_ACTION_MARGIN;
        } else if (newCenterPosition < originalCenter - QUICK_ACTION_MARGIN && self.leftStyle == CPSwipeableTableViewCellSwipeStyleQuickAction) {
            newCenterPosition = originalCenter - QUICK_ACTION_MARGIN;
        }
		
		// Let's not go waaay out of bounds
		if (newCenterPosition > self.bounds.size.width + originalCenter)
			newCenterPosition = self.bounds.size.width + originalCenter;
		
		else if (newCenterPosition < -originalCenter)
			newCenterPosition = -originalCenter;
        
        // reposition the icons in the background view depending on the center position
        [self repositionSecretIconsForCenterX:newCenterPosition];
		
		CGPoint center = self.contentView.center;
		center.x = newCenterPosition;
		
		self.contentView.layer.position = center;
		
	} else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        
		// Swiping left, velocity is below 0.
		// Swiping right, it is above 0
		// If the velocity is above the width in points per second at any point in the pan, push it to the acceptable side
		// Otherwise, if we are 60 points in, push to the other side
		// If we are < 60 points in, bounce back
		
#define kMinimumVelocity self.contentView.frame.size.width
#define kMinimumPan      60.0
		
		CGFloat velocityX = velocity.x;
        BOOL push = NO;
        
        // the minimum pan is defined above but is different if it's a quick action
        CGFloat minPan = [self styleForDirectionIsQuickAction:self.lastDirection] ? QUICK_ACTION_MARGIN : kMinimumPan;
        
		push |= ((self.lastDirection == CPSwipeableTableViewCellDirectionLeft && translation.x < -minPan) || (self.lastDirection == CPSwipeableTableViewCellDirectionRight && translation.x > minPan));
        
        // only consider the velocity if this isn't for a quick action
        if (![self styleForDirectionIsQuickAction:self.lastDirection]) {
            push |= (velocityX < -kMinimumVelocity);
            push |= (velocityX > kMinimumVelocity);
            
            if (velocityX > 0 && self.lastDirection == CPSwipeableTableViewCellDirectionLeft)
                push = NO;
            
            else if (velocityX < 0 && self.lastDirection == CPSwipeableTableViewCellDirectionRight)
                push = NO;
        }
        
		push &= self.shouldReveal;
		push &= ((self.lastDirection == CPSwipeableTableViewCellDirectionRight && self.shouldDragRight) || (self.lastDirection == CPSwipeableTableViewCellDirectionLeft && self.shouldDragLeft));
        
		if (push && !self.isRevealing) {
			[self _setRevealing:YES];
			[self performActionInDirection:self.lastDirection];
            
			self.currentDirection = self.lastDirection;
			
		} else if (self.isRevealing && translation.x != 0) {
			CGFloat multiplier = self.bounceMultiplier;
			if (!self.isRevealing)
				multiplier *= -1.0;
            
			[self slideInContentViewFromDirection:self.currentDirection offsetMultiplier:multiplier];
			[self _setRevealing:NO];
			
		} else if (translation.x != 0) {
			// Figure out which side we've dragged on.
			CPSwipeableTableViewCellDirection finalDir = CPSwipeableTableViewCellDirectionRight;
			if (translation.x < 0)
				finalDir = CPSwipeableTableViewCellDirectionLeft;
            
			[self slideInContentViewFromDirection:finalDir offsetMultiplier:-1.0 * self.bounceMultiplier];
			[self _setRevealing:NO];
		}
	}
}


- (BOOL)shouldDragLeft
{
	return (self.leftStyle == CPSwipeableTableViewCellSwipeStyleFull || self.leftStyle == CPSwipeableTableViewCellSwipeStyleQuickAction);
}

- (BOOL)shouldDragRight
{
    return (self.rightStyle == CPSwipeableTableViewCellSwipeStyleFull || self.rightStyle == CPSwipeableTableViewCellSwipeStyleQuickAction);
}

- (BOOL)styleForDirectionIsQuickAction:(CPSwipeableTableViewCellDirection)direction 
{
    return ((direction == CPSwipeableTableViewCellDirectionLeft && self.leftStyle == CPSwipeableTableViewCellSwipeStyleQuickAction) ||
            (direction == CPSwipeableTableViewCellDirectionRight && self.rightStyle == CPSwipeableTableViewCellSwipeStyleQuickAction));
}

- (CGFloat)originalCenter
{
    return ceil(self.bounds.size.width / 2);
}

- (CGFloat)bounceMultiplier
{
	return self.shouldBounce ? MIN(ABS(self.originalCenter - self.contentView.center.x) / kMinimumPan, 1.0) : 0.0;
}

#pragma mark - Sliding
#define kBOUNCE_DISTANCE 20.0

- (void)slideInContentViewFromDirection:(CPSwipeableTableViewCellDirection)direction offsetMultiplier:(CGFloat)multiplier
{    
    CGFloat bounceDistance;
    
    if ([self styleForDirectionIsQuickAction:direction]) {
        // this was from a quick action and we're forcing a hide
        // so make sure we set revealing to NO
        [self _setRevealing:NO];
    }
	
	if (self.contentView.center.x == self.originalCenter)
		return;
	
	switch (direction) {
		case CPSwipeableTableViewCellDirectionRight:
			bounceDistance = kBOUNCE_DISTANCE * multiplier;
			break;
		case CPSwipeableTableViewCellDirectionLeft:
			bounceDistance = -kBOUNCE_DISTANCE * multiplier;
			break;
		default:
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unhandled gesture direction" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:direction] forKey:@"direction"]];
			break;
	}
	
	[UIView animateWithDuration:0.1
						  delay:0 
						options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction 
					 animations:^{ self.contentView.center = CGPointMake(self.originalCenter, self.contentView.center.y); } 
					 completion:^(BOOL f) {
                         
						 [UIView animateWithDuration:0.1 delay:0 
											 options:UIViewAnimationCurveLinear
										  animations:^{ self.contentView.frame = CGRectOffset(self.contentView.frame, bounceDistance, 0); } 
										  completion:^(BOOL f) {                     
											  
                                              [UIView animateWithDuration:0.1 delay:0 
                                                                  options:UIViewAnimationCurveLinear
                                                               animations:^{ self.contentView.frame = CGRectOffset(self.contentView.frame, -bounceDistance, 0); } 
                                                               completion:NULL];
										  }
						  ]; 
					 }];
}

- (void)slideOutContentViewToNewCenterX:(CGFloat)centerX;
{
    [UIView animateWithDuration:0.2 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseOut 
					 animations:^{ self.contentView.center = CGPointMake(centerX, self.contentView.center.y); } 
					 completion:NULL];
}

- (void)performActionInDirection:(CPSwipeableTableViewCellDirection)direction;
{
    if ([self styleForDirectionIsQuickAction:direction]) {
        // make sure the delegate will handle the call
        // and then tell it to perform the quick action
        if ([self.delegate respondsToSelector:@selector(quickActionForDirection:cell:)]) {
            [self.delegate quickActionForDirection:direction cell:self];
        }
        
        // slide the content view back in
        // by setting revealing to NO using the delegate's method
        [self slideInContentViewFromDirection:direction offsetMultiplier:[self bounceMultiplier]];
    } else {
        // calculate the new center depending on the direction of the swipe
        CGFloat x = direction == CPSwipeableTableViewCellDirectionLeft ? -self.originalCenter : self.contentView.frame.size.width + self.originalCenter; 
        [self slideOutContentViewToNewCenterX:x];
    }
}

- (void)repositionSecretIconsForCenterX:(CGFloat)centerX
{        
    // make sure we actually have images to show
    if (self.secretImageViews.count > 0) {
        
# define CONTAINER_SHADOW_FIRST_TAG 8832
        
        // get the position of the left edge of the cell
        CGFloat leftEdge = centerX - (self.contentView.frame.size.width / 2);
        
        // grab the first actionButton
        UIButton *actionButton = [self.secretButtons objectAtIndex:0];
        
        // CGFloat set to half the side of the button, used for center calculations
        CGFloat halfButton = (actionButton.frame.size.height / 2);
        
        // get the destination point for the base of the button
        CGFloat buttonBaseDesination = (self.contentView.frame.size.height / 2) + (halfButton - PADDING_TO_CONTAINER_IMAGE);
        
        // grab the first secretIcon
        UIImageView *secretImageView = [self.secretImageViews objectAtIndex:0];
        
        // only move the button and the imageView if they'll be displayed
        if (leftEdge >= BUTTON_LEFT_MARGIN) {
            
            // the cell is at what % of its destination?
            CGFloat cellClose = (leftEdge - BUTTON_LEFT_MARGIN) / (QUICK_ACTION_MARGIN - BUTTON_LEFT_MARGIN);
            
            // we want the base to also be that close to where it's going
            CGFloat newBase = cellClose * buttonBaseDesination;
            
            // calculate a new center point based on the position of the left edge of the cell
            CGFloat newCenterY = newBase - (halfButton - PADDING_TO_CONTAINER_IMAGE);
            
            // set the new center for the actionButton
            CGPoint newCenter = actionButton.center;
            newCenter.y = newCenterY;
            actionButton.center = newCenter;
            
            // change the center for the bottom heart
            newCenter.y = self.contentView.frame.size.height - newCenterY;
            
            // set the new center for the secretImageView
            secretImageView.center = newCenter;
            
            // calculate an alpha based on how close the elements are to the center
            CGFloat changingAlpha = cellClose;
            
            // set the calculated alpha value on each element
            actionButton.alpha = changingAlpha;
            secretImageView.alpha = changingAlpha;
            
        }
        
        // if the the icon is locked then start the shadow beam
        if (leftEdge >= QUICK_ACTION_MARGIN) {
            
            // but only if we don't already have it
            if (![self.hiddenView viewWithTag:CONTAINER_SHADOW_FIRST_TAG]) {
                // setup a UIImageView to hold the beam image
                UIImageView *shadowBeam = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"action-button-container-glow"]];
                
                // give the shadowBeam the right tag
                shadowBeam.tag = CONTAINER_SHADOW_FIRST_TAG;
                
                // start the shadowBeam at alpha 0
                shadowBeam.alpha = 0.0;
                
                // center the UIImageView with the button
                shadowBeam.center  = actionButton.center;
                
                // add the shadowBeam below the button
                [self.hiddenView insertSubview:shadowBeam belowSubview:actionButton];
                
                // call shadowBeamForContainer to start pulsing it
                [self shadowBeamForContainer:shadowBeam];
            }
        } else {
            // remove the shadow beam from the button container
            [[self.hiddenView viewWithTag:CONTAINER_SHADOW_FIRST_TAG] removeFromSuperview];
        }

    }    
}

-(void)shadowBeamForContainer:(UIImageView *)beamImageView 
{
    // start a repeating animation to pulse the shadow beam on the button
    [UIView animateWithDuration:0.5 delay:0.0 options:(UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat) animations:^{
        beamImageView.alpha = 1.0;
    } completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // make sure this is the pan gesture
    if (gestureRecognizer == self.panRecognizer) {
        
        // how far as the cell moved with relation to the table view?
		UIScrollView *superview = (UIScrollView *)self.superview;
		CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:superview];
		
		// make sure it's scrolling horizontally
		return ((fabs(translation.x) / fabs(translation.y) > 1) ? YES : NO && (superview.contentOffset.y == 0.0 && superview.contentOffset.x == 0.0));
	}
	return NO;
}

- (void)toggleCellActiveState:(BOOL)active
{
    if (active) {
        self.contentView.layer.backgroundColor = [UIColor colorWithR:66 G:128 B:128 A:1].CGColor;
    } else {
        self.contentView.layer.backgroundColor = [UIColor colorWithR:51 G:51 B:51 A:1].CGColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self toggleCellActiveState:highlighted];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self toggleCellActiveState:selected];
}

@end