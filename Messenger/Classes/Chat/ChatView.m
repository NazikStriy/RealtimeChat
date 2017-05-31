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

#import "ChatView.h"
#import "GroupView.h"
#import "ProfileView.h"
#import "CallAudioView.h"
#import "CallVideoView.h"
#import "PictureView.h"
#import "VideoView.h"
#import "MapView.h"
#import "StickersView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ChatView()
{
	NSString *groupId;
	NSArray *members;
	NSString *type;

	BOOL isGroup;
	BOOL isPrivate;

	NSString *userId;
	BOOL isBlocker;

	NSInteger typingCounter;
	NSInteger insertCounter;

	Messages *messages;
	FIRDatabaseReference *firebase;

	RLMResults *dbmessages;
	NSMutableDictionary *jsqmessages;

	NSMutableArray *avatarIds;
	NSMutableDictionary *avatars;
	NSMutableDictionary *initials;

	JSQMessagesBubbleImage *bubbleImageOutgoing;
	JSQMessagesBubbleImage *bubbleImageIncoming;
}

@property (strong, nonatomic) IBOutlet UIView *viewTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelDetails;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ChatView

@synthesize viewTitle, labelTitle, labelDetails;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	groupId = dictionary[@"groupId"];
	members = dictionary[@"members"];
	type = dictionary[@"type"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	isGroup = [type isEqualToString:CHAT_GROUP];
	isPrivate = [type isEqualToString:CHAT_PRIVATE];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isPrivate)
	{
		NSString *userId1 = [members firstObject];
		NSString *userId2 = [members lastObject];
		if ([userId1 isEqualToString:[FUser currentId]]) userId = userId2;
		if ([userId2 isEqualToString:[FUser currentId]]) userId = userId1;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	isBlocker = (userId != nil) ? [Blocked isBlocker:userId] : NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.titleView = viewTitle;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chat_back"]
																	style:UIBarButtonItemStylePlain target:self action:@selector(actionBack)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *buttonRight1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chat_callaudio"] style:UIBarButtonItemStylePlain
																	target:self action:@selector(actionCallAudio)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *buttonRight2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chat_callvideo"] style:UIBarButtonItemStylePlain
																	target:self action:@selector(actionCallVideo)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((isPrivate) && (isBlocker == NO))
		self.navigationItem.rightBarButtonItems = @[buttonRight1, buttonRight2];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationController.interactivePopGestureRecognizer.delegate = self;
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_CLEANUP_CHATVIEW];
	[NotificationCenter addObserver:self selector:@selector(refreshCollectionView1) name:NOTIFICATION_REFRESH_MESSAGES1];
	[NotificationCenter addObserver:self selector:@selector(refreshCollectionView2) name:NOTIFICATION_REFRESH_MESSAGES2];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	insertCounter = INSERT_MESSAGES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	jsqmessages = [[NSMutableDictionary alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	avatarIds = [[NSMutableArray alloc] init];
	avatars = [[NSMutableDictionary alloc] init];
	initials = [[NSMutableDictionary alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser wallpaper] != nil)
		self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[FUser wallpaper]]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
	bubbleImageOutgoing = [bubbleFactory outgoingMessagesBubbleImageWithColor:COLOR_OUTGOING];
	bubbleImageIncoming = [bubbleFactory incomingMessagesBubbleImageWithColor:COLOR_INCOMING];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	[JSQMessagesCollectionViewCell registerMenuAction:@selector(actionCopy:)];
	[JSQMessagesCollectionViewCell registerMenuAction:@selector(actionDelete:)];
	[JSQMessagesCollectionViewCell registerMenuAction:@selector(actionSave:)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(actionCopy:)];
	UIMenuItem *menuItemDelete = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(actionDelete:)];
	UIMenuItem *menuItemSave = [[UIMenuItem alloc] initWithTitle:@"Save" action:@selector(actionSave:)];
	[UIMenuController sharedMenuController].menuItems = @[menuItemCopy, menuItemDelete, menuItemSave];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent clearCounter:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	messages = [[Messages alloc] initWith:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	firebase = [[[FIRDatabase database] referenceWithPath:FTYPING_PATH] child:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadMessages];
	[self createTypingObservers];
	//---------------------------------------------------------------------------------------------------------------------------------------------
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillAppear:animated];
	[self updateTitleDetails];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isBlocker) self.inputToolbar.contentView.textView.userInteractionEnabled = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillDisappear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.view endEditing:YES];
}

#pragma mark - Custom menu actions for cells

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIMenuController *menu = [notification object];
	UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(actionCopy:)];
	UIMenuItem *menuItemDelete = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(actionDelete:)];
	UIMenuItem *menuItemSave = [[UIMenuItem alloc] initWithTitle:@"Save" action:@selector(actionSave:)];
	menu.menuItems = @[menuItemCopy, menuItemDelete, menuItemSave];
}

#pragma mark - Realm methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadMessages
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self.automaticallyScrollsToMostRecentMessage = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupId == %@ AND isDeleted == NO", groupId];
	dbmessages = [[DBMessage objectsWithPredicate:predicate] sortedResultsUsingProperty:FMESSAGE_CREATEDAT ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshCollectionView2];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)insertMessages
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	insertCounter += INSERT_MESSAGES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshCollectionView2];
}

#pragma mark - Title details methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateTitleDetails
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (isPrivate)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", userId];
		DBUser *dbuser = [[DBUser objectsWithPredicate:predicate] firstObject];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		self.labelTitle.text = dbuser.fullname;
		self.labelDetails.text = UserLastActive(dbuser);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isGroup)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", groupId];
		DBGroup *dbgroup = [[DBGroup objectsWithPredicate:predicate] firstObject];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		members = [dbgroup.members componentsSeparatedByString:@","];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		self.labelTitle.text = dbgroup.name;
		self.labelDetails.text = [NSString stringWithFormat:@"%ld members", (long) [members count]];
	}
}

#pragma mark - Refresh methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshCollectionView1
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self refreshCollectionView2];
	[self finishReceivingMessage];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshCollectionView2
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self.showLoadEarlierMessagesHeader = (insertCounter < [dbmessages count]);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.collectionView reloadData];
}

#pragma mark - Backend methods (avatar)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadAvatar:(NSString *)senderId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([avatarIds containsObject:senderId]) return;
	else [avatarIds addObject:senderId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", senderId];
	DBUser *dbuser = [[DBUser objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[DownloadManager image:dbuser.thumbnail completion:^(NSString *path, NSError *error, BOOL network)
	{
		if (error == nil)
		{
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
			avatars[senderId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:30];
			//-------------------------------------------------------------------------------------------------------------------------------------
			dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
			dispatch_after(time, dispatch_get_main_queue(), ^{ [self.collectionView reloadData]; });
		}
		else if (error.code != 100) [avatarIds removeObject:senderId];
	}];
}

#pragma mark - Message sendig methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)messageSend:(NSString *)text Video:(NSURL *)video Picture:(UIImage *)picture Audio:(NSString *)audio
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([Connection isReachable])
	{
		UIView *view = self.navigationController.view;
		[MessageSend1 send:groupId status:nil text:text picture:picture video:video audio:audio view:view];
	}
	else
	{
		AdvertPremium(self);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isPrivate) [Shortcut update:userId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self finishSendingMessage];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)messageDelete:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	[Message deleteItem:dbmessage];
}

#pragma mark - Typing indicator methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createTypingObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		if ([snapshot.key isEqualToString:[FUser currentId]] == NO)
		{
			BOOL typing = [snapshot.value boolValue];
			self.showTypingIndicator = typing;
			if (typing) [self scrollToBottomAnimated:YES];
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorStart
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	typingCounter++;
	[self typingIndicatorSave:@YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self typingIndicatorStop]; });
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorStop
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	typingCounter--;
	if (typingCounter == 0) [self typingIndicatorSave:@NO];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorSave:(NSNumber *)typing
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase updateChildValues:@{[FUser currentId]:typing}];
}

#pragma mark - UITextViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self typingIndicatorStart];
	return YES;
}

#pragma mark - JSQMessagesViewController method overrides

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId
		 senderDisplayName:(NSString *)name date:(NSDate *)date
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageSend:text Video:nil Picture:nil Audio:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressAccessoryButton:(UIButton *)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self actionAttach];
}

#pragma mark - JSQMessages CollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)senderId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [FUser currentId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)senderDisplayName
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [FUser fullname];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	NSString *messageId = dbmessage.objectId;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (jsqmessages[messageId] == nil)
	{
		Incoming *incoming = [[Incoming alloc] initWith:dbmessage CollectionView:self.collectionView];
		jsqmessages[messageId] = [incoming createMessage];
	}
	return jsqmessages[messageId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
			 messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self outgoing:indexPath])
	{
		return bubbleImageOutgoing;
	}
	else return bubbleImageIncoming;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
					avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	NSString *senderId = dbmessage.senderId;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (avatars[senderId] == nil)
	{
		[self loadAvatar:senderId];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (initials[senderId] == nil)
	{
		initials[senderId] = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:dbmessage.senderInitials
								backgroundColor:HEXCOLOR(0xE4E4E4FF) textColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14] diameter:30];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return (avatars[senderId] != nil) ? avatars[senderId] : initials[senderId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView
	attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.item % 3 == 0)
	{
		JSQMessage *jsqmessage = [self jsqmessage:indexPath];
		return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:jsqmessage.date];
	}
	else return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView
	attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self incoming:indexPath])
	{
		DBMessage *dbmessage = [self dbmessage:indexPath];
		if (indexPath.item > 0)
		{
			DBMessage *dbprevious = [self dbmessage:[NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section]];
			if ([dbprevious.senderId isEqualToString:dbmessage.senderId])
			{
				return nil;
			}
		}
		return [[NSAttributedString alloc] initWithString:dbmessage.senderName];
	}
	else return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self outgoing:indexPath])
	{
		DBMessage *dbmessage = [self dbmessage:indexPath];
		return [[NSAttributedString alloc] initWithString:dbmessage.status];
	}
	else return nil;
}

#pragma mark - UICollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return MIN(insertCounter, [dbmessages count]);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIColor *color = [self outgoing:indexPath] ? [UIColor whiteColor] : [UIColor blackColor];

	JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
	cell.textView.textColor = color;
	cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName:color};

	return cell;
}

#pragma mark - UICollectionView Delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)collectionView:(JSQMessagesCollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super collectionView:collectionView shouldShowMenuForItemAtIndexPath:indexPath];
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath
			withSender:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (action == @selector(actionCopy:))
	{
		if ([dbmessage.type isEqualToString:MESSAGE_TEXT]) return YES;
		if ([dbmessage.type isEqualToString:MESSAGE_EMOJI]) return YES;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (action == @selector(actionDelete:))
	{
		if ([self outgoing:indexPath]) return YES;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (action == @selector(actionSave:))
	{
		if ([dbmessage.type isEqualToString:MESSAGE_PICTURE]) return YES;
		if ([dbmessage.type isEqualToString:MESSAGE_VIDEO]) return YES;
		if ([dbmessage.type isEqualToString:MESSAGE_AUDIO]) return YES;
	}
	return NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath
			withSender:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (action == @selector(actionCopy:))	[self actionCopy:indexPath];
	if (action == @selector(actionDelete:))	[self actionDelete:indexPath];
	if (action == @selector(actionSave:))	[self actionSave:indexPath];
}

#pragma mark - JSQMessages collection view flow layout delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
	heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.item % 3 == 0)
	{
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
	heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self incoming:indexPath])
	{
		DBMessage *dbmessage = [self dbmessage:indexPath];
		if (indexPath.item > 0)
		{
			DBMessage *dbprevious = [self dbmessage:[NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section]];
			if ([dbprevious.senderId isEqualToString:dbmessage.senderId])
			{
				return 0;
			}
		}
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
	heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self outgoing:indexPath])
	{
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

#pragma mark - Responding to collection view tap events

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView header:(JSQMessagesLoadEarlierHeaderView *)headerView
	didTapLoadEarlierMessagesButton:(UIButton *)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self insertMessages];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView
		   atIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	NSString *senderId = dbmessage.senderId;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([senderId isEqualToString:[FUser currentId]] == NO)
	{
		ProfileView *profileView = [[ProfileView alloc] initWith:senderId Chat:NO];
		[self.navigationController pushViewController:profileView animated:YES];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	JSQMessage *jsqmessage = [self jsqmessage:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_PICTURE])
	{
		PhotoMediaItem *mediaItem = (PhotoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_MANUAL)
		{
			[MediaManager loadPictureManual:mediaItem dbmessage:dbmessage collectionView:collectionView];
			[collectionView reloadData];
		}
		if (mediaItem.status == STATUS_SUCCEED)
		{
			PictureView *pictureView = [[PictureView alloc] initWith:dbmessage.objectId groupId:groupId];
			[self presentViewController:pictureView animated:YES completion:nil];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_VIDEO])
	{
		VideoMediaItem *mediaItem = (VideoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_MANUAL)
		{
			[MediaManager loadVideoManual:mediaItem dbmessage:dbmessage collectionView:collectionView];
			[collectionView reloadData];
		}
		if (mediaItem.status == STATUS_SUCCEED)
		{
			VideoView *videoView = [[VideoView alloc] initWith:mediaItem.fileURL];
			[self presentViewController:videoView animated:YES completion:nil];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_AUDIO])
	{
		AudioMediaItem *mediaItem = (AudioMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_MANUAL)
		{
			[MediaManager loadAudioManual:mediaItem dbmessage:dbmessage collectionView:collectionView];
			[collectionView reloadData];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_LOCATION])
	{
		JSQLocationMediaItem *mediaItem = (JSQLocationMediaItem *)jsqmessage.media;
		MapView *mapView = [[MapView alloc] initWith:mediaItem.location];
		NavigationController *navController = [[NavigationController alloc] initWithRootViewController:mapView];
		[self presentViewController:navController animated:YES completion:nil];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath
		 touchLocation:(CGPoint)touchLocation
//-------------------------------------------------------------------------------------------------------------------------------------------------
{

}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionBack
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// This can be removed once JSQAudioMediaItem audioPlayer issue is fixed
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBMessage *dbmessage in dbmessages)
	{
		if ([dbmessage.type isEqualToString:MESSAGE_AUDIO])
		{
			JSQMessage *jsqmessage = jsqmessages[dbmessage.objectId];
			AudioMediaItem *mediaItem = (AudioMediaItem *)jsqmessage.media;
			[mediaItem stopAudioPlayer];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self actionCleanup];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.navigationController popViewControllerAnimated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionDetails:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (isPrivate)
	{
		ProfileView *profileView = [[ProfileView alloc] initWith:userId Chat:NO];
		[self.navigationController pushViewController:profileView animated:YES];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isGroup)
	{
		GroupView *groupView = [[GroupView alloc] initWith:groupId];
		[self.navigationController pushViewController:groupView animated:YES];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCallAudio
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertPremium(self);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCallVideo
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertPremium(self);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageDelete:indexPath];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCopy:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	[[UIPasteboard generalPasteboard] setString:dbmessage.text];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSave:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	JSQMessage *jsqmessage = [self jsqmessage:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_PICTURE])
	{
		PhotoMediaItem *mediaItem = (PhotoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_SUCCEED)
			UIImageWriteToSavedPhotosAlbum(mediaItem.image, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_VIDEO])
	{
		VideoMediaItem *mediaItem = (VideoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_SUCCEED)
			UISaveVideoAtPathToSavedPhotosAlbum(mediaItem.fileURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_AUDIO])
	{
		AudioMediaItem *mediaItem = (AudioMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_SUCCEED)
		{
			NSString *path = [File temp:@"mp4"];
			[mediaItem.audioData writeToFile:path atomically:NO];
			UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
		}
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (error == nil)
	{
		[ProgressHUD showSuccess:@"Successfully saved."];
	}
	else [ProgressHUD showError:@"Save failed."];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionAttach
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (isBlocker) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.view endEditing:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { PresentMultiCamera(self, YES); }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Picture" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { PresentPhotoLibrary(self, YES); }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Video" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { PresentVideoLibrary(self, YES); }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Audio" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionAudio]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Sticker" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionStickers]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Location" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionLocation]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionAudio
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
	controller.delegate = self;
	controller.title = @"Recorder";
	controller.maximumRecordDuration = AUDIO_LENGTH;
	controller.allowCropping = NO;
	[self.tabBarController presentBlurredAudioRecorderViewControllerAnimated:controller];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionStickers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	StickersView *stickersView = [[StickersView alloc] init];
	stickersView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:stickersView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionLocation
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageSend:nil Video:nil Picture:nil Audio:nil];
}

#pragma mark - UIImagePickerControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSURL *video = info[UIImagePickerControllerMediaURL];
	UIImage *picture = info[UIImagePickerControllerEditedImage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self messageSend:nil Video:video Picture:picture Audio:nil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IQAudioRecorderViewControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)audioRecorderController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)path
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageSend:nil Video:nil Picture:nil Audio:path];
	[controller dismissViewControllerAnimated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - StickersDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectSticker:(NSString *)sticker
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIImage *picture = [UIImage imageNamed:sticker];
	[self messageSend:nil Video:nil Picture:picture Audio:nil];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[messages actionCleanup]; messages = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent clearCounter:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[firebase removeAllObservers]; firebase = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter removeObserver:self];
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)index:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger count = MIN(insertCounter, [dbmessages count]);
	NSInteger offset = [dbmessages count] - count;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return (indexPath.item + offset);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (DBMessage *)dbmessage:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger index = [self index:indexPath];
	return dbmessages[index];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)jsqmessage:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	return jsqmessages[dbmessage.objectId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)incoming:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	return ([dbmessage.senderId isEqualToString:[FUser currentId]] == NO);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)outgoing:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBMessage *dbmessage = [self dbmessage:indexPath];
	return ([dbmessage.senderId isEqualToString:[FUser currentId]] == YES);
}

@end
