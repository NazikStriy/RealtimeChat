//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PictureView.h"
#import "SelectUsersView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface PictureView()
{
	BOOL isMessages;
	BOOL statusBarIsHidden;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation PictureView

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(UIImage *)picture
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	isMessages = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NYTPhotoItem *photoItem = [[NYTPhotoItem alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	photoItem.image = picture;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self = [super initWithPhotos:@[photoItem]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)objectId groupId:(NSString *)groupId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	isMessages = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NYTPhotoItem *initialPhoto;
	NSMutableArray *photoItems = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupId == %@ AND type == %@ AND isDeleted == NO", groupId, MESSAGE_PICTURE];
	RLMResults *dbmessages = [[DBMessage objectsWithPredicate:predicate] sortedResultsUsingProperty:FMESSAGE_CREATEDAT ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSDictionary *attributesTitle = @{NSForegroundColorAttributeName:[UIColor whiteColor],
									 NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSDictionary *attributesCredit = @{NSForegroundColorAttributeName:[UIColor grayColor],
									   NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBMessage *dbmessage in dbmessages)
	{
		NSString *path = [DownloadManager pathImage:dbmessage.picture];
		if (path != nil)
		{
			NSString *title = dbmessage.senderName;
			//-------------------------------------------------------------------------------------------------------------------------------------
			NSDate *date = [NSDate dateWithTimestamp:dbmessage.createdAt];
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"dd MMMM, HH:mm"];
			NSString *credit = [dateFormatter stringFromDate:date];
			//-------------------------------------------------------------------------------------------------------------------------------------
			NYTPhotoItem *photoItem = [[NYTPhotoItem alloc] init];
			photoItem.image = [[UIImage alloc] initWithContentsOfFile:path];
			photoItem.attributedCaptionTitle = [[NSAttributedString alloc] initWithString:title attributes:attributesTitle];
			photoItem.attributedCaptionCredit = [[NSAttributedString alloc] initWithString:credit attributes:attributesCredit];
			photoItem.objectId = dbmessage.objectId;
			//-------------------------------------------------------------------------------------------------------------------------------------
			if ([dbmessage.objectId isEqualToString:objectId]) initialPhoto = photoItem;
			//-------------------------------------------------------------------------------------------------------------------------------------
			[photoItems addObject:photoItem];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self = [super initWithPhotos:photoItems initialPhoto:initialPhoto delegate:nil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	statusBarIsHidden = [UIApplication sharedApplication].isStatusBarHidden;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isMessages)
	{
		UIBarButtonItem *buttonMore = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
																					action:@selector(actionMore)];
		UIBarButtonItem *buttonDelete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self
																					  action:@selector(actionDelete)];
		self.rightBarButtonItems = @[buttonMore, buttonDelete];
	}
	else self.rightBarButtonItem = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self updateOverlayViewConstraints];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)prefersStatusBarHidden
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return statusBarIsHidden;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UIStatusBarStyle)preferredStatusBarStyle
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return UIStatusBarStyleLightContent;
}

#pragma mark - Initialization methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateOverlayViewConstraints
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	for (NSLayoutConstraint *constraint in self.overlayView.constraints)
	{
		if ([constraint.firstItem isKindOfClass:[UINavigationBar class]])
		{
			if (constraint.firstAttribute == NSLayoutAttributeTop)
			{
				constraint.constant = 20;
			}
		}
	}
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMore
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionSave]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Forward" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionForward]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionShare]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - User actions (save)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSave
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertCustom(self);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
}

#pragma mark - User actions (forward)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionForward
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertCustom(self);
}

#pragma mark - SelectUsersDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectUsers:(NSMutableArray *)users groups:(NSMutableArray *)groups
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
}

#pragma mark - User actions (share)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionShare
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertCustom(self);
}

#pragma mark - User actions (delete)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
											handler:^(UIAlertAction *action) { [self actionDeletePhoto]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDeletePhoto
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertCustom(self);
}

@end
