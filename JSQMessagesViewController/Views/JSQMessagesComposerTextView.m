//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesComposerTextView.h"

#import <QuartzCore/QuartzCore.h>

#import "NSString+JSQMessages.h"


@implementation JSQMessagesComposerTextView

#pragma mark - Initialization

- (void)jsq_configureTextView
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    CGFloat cornerRadius = 6.0f;
    
    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.cornerRadius = cornerRadius;
    
    self.scrollIndicatorInsets = UIEdgeInsetsMake(cornerRadius, 0.0f, cornerRadius, 0.0f);
    
    self.textContainerInset = UIEdgeInsetsMake(4.0f, 2.0f, 4.0f, 2.0f);
    
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.userInteractionEnabled = YES;
    
    self.font = [UIFont systemFontOfSize:16.0f];
    self.textColor = [UIColor blackColor];
    self.textAlignment = NSTextAlignmentNatural;
    
    self.contentMode = UIViewContentModeRedraw;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.keyboardAppearance = UIKeyboardAppearanceDefault;
    self.keyboardType = UIKeyboardTypeDefault;
    self.returnKeyType = UIReturnKeyDefault;
    
    self.text = nil;
    
    _placeHolder = nil;
    _placeHolderTextColor = [UIColor lightGrayColor];
    _verticalAlignment = JSQMessagesComposerTextViewVerticalAlignmentDefault;
    
    [self invalidateContentInset];
    [self jsq_addTextViewNotificationObservers];
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self jsq_configureTextView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self jsq_configureTextView];
}

- (void)dealloc
{
    [self jsq_removeTextViewNotificationObservers];
}

#pragma mark - Composer text view

- (BOOL)hasText
{
    return ([[self.text jsq_stringByTrimingWhitespace] length] > 0);
}

#pragma mark - Setters

- (void)setPlaceHolder:(NSString *)placeHolder
{
    if ([placeHolder isEqualToString:_placeHolder]) {
        return;
    }
    
    _placeHolder = [placeHolder copy];
    [self setNeedsDisplay];
}

- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor
{
    if ([placeHolderTextColor isEqual:_placeHolderTextColor]) {
        return;
    }
    
    _placeHolderTextColor = placeHolderTextColor;
    [self setNeedsDisplay];
}

#pragma mark - UITextView overrides

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    [self setNeedsDisplay];
}

- (void)paste:(id)sender
{
    if (!self.jsq_pasteDelegate || [self.jsq_pasteDelegate composerTextView:self shouldPasteWithSender:sender]) {
        [super paste:sender];
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if ([self.text length] == 0 && self.placeHolder) {
        [self.placeHolderTextColor set];
        
        NSDictionary * attributes = [self jsq_placeholderTextAttributes];
        CGRect insetRect = CGRectInset(rect, 7.0f, 5.0f);
        
        switch (self.verticalAlignment) {
            case JSQMessagesComposerTextViewVerticalAlignmentCenter:
            {
                CGSize placeHolderTextSize = [self.placeHolder sizeWithAttributes:attributes];
                CGRect placeHolderRect = CGRectMake(insetRect.origin.x,
                                                    insetRect.origin.y + (insetRect.size.height - placeHolderTextSize.height) * 0.5f,
                                                    insetRect.size.width,
                                                    placeHolderTextSize.height);
                [self.placeHolder drawInRect:placeHolderRect withAttributes:attributes];
                break;
            }
            case JSQMessagesComposerTextViewVerticalAlignmentDefault:
            default:
                [self.placeHolder drawInRect:insetRect
                              withAttributes:attributes];
                break;
        }
    }
}

#pragma mark - Notifications

- (void)jsq_addTextViewNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self];
}

- (void)jsq_removeTextViewNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidChangeNotification
                                                  object:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidBeginEditingNotification
                                                  object:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidEndEditingNotification
                                                  object:self];
}

- (void)jsq_didReceiveTextViewNotification:(NSNotification *)notification
{
    [self setNeedsDisplay];
}

#pragma mark - Utilities

- (NSDictionary *)jsq_placeholderTextAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = self.textAlignment;
    
    return @{ NSFontAttributeName : self.font,
              NSForegroundColorAttributeName : self.placeHolderTextColor,
              NSParagraphStyleAttributeName : paragraphStyle };
}

#pragma mark - Alignment

- (void)invalidateContentInset
{
    if ( self.verticalAlignment == JSQMessagesComposerTextViewVerticalAlignmentDefault ) {
        self.contentInset = UIEdgeInsetsMake(1.0f, 0.0f, 1.0f, 0.0f);
        return;
    }
    
    CGSize size = [self sizeThatFits:self.frame.size];
    CGFloat offsetY = (CGRectGetHeight(self.frame) - size.height) * 0.5f;
    offsetY = offsetY < 0.0f ? 0.0f : offsetY;
    self.contentInset = UIEdgeInsetsMake(offsetY, 0.0f, 0.0f, 0.0f);
}

@end
