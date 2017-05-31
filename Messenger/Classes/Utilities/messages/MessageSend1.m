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

#import "MessageSend1.h"

@implementation MessageSend1

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)send:(NSString *)groupId status:(NSString *)status text:(NSString *)text picture:(UIImage *)picture video:(NSURL *)video
	   audio:(NSString *)audio view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_GROUPID] = groupId;
	message[FMESSAGE_SENDERID] = [FUser currentId];
	message[FMESSAGE_SENDERNAME] = [FUser fullname];
	message[FMESSAGE_SENDERINITIALS] = [FUser initials];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_PICTURE] = @"";
	message[FMESSAGE_PICTURE_WIDTH] = @0;
	message[FMESSAGE_PICTURE_HEIGHT] = @0;
	message[FMESSAGE_PICTURE_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_VIDEO] = @"";
	message[FMESSAGE_VIDEO_DURATION] = @0;
	message[FMESSAGE_VIDEO_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_AUDIO] = @"";
	message[FMESSAGE_AUDIO_DURATION] = @0;
	message[FMESSAGE_AUDIO_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_LATITUDE] = @0;
	message[FMESSAGE_LONGITUDE] = @0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_STATUS] = TEXT_SENT;
	message[FMESSAGE_ISDELETED] = @NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (status != nil)			[self sendStatusMessage:message status:status];
	else if (text != nil)		[self sendTextMessage:message text:text];
	else if (picture != nil)	[self sendPictureMessage:message picture:picture view:view];
	else if (video != nil)		[self sendVideoMessage:message video:video view:view];
	else if (audio != nil)		[self sendAudioMessage:message audio:audio view:view];
	else						[self sendLoactionMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendStatusMessage:(FObject *)message status:(NSString *)status
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_STATUS;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:status groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendTextMessage:(FObject *)message text:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = [Emoji isEmoji:text] ? MESSAGE_EMOJI : MESSAGE_TEXT;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:text groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendPictureMessage:(FObject *)message picture:(UIImage *)picture view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_PICTURE;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Picture message]" groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataPicture = UIImageJPEGRepresentation(picture, 0.6);
	NSData *cryptedPicture = [Cryptor encryptData:dataPicture groupId:groupId];
	NSString *md5Picture = [Checksum md5HashOfData:cryptedPicture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_image", @"jpg")];
	FIRStorageUploadTask *task = [reference putData:cryptedPicture metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileImage:link];
			[dataPicture writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_PICTURE] = link;
			message[FMESSAGE_PICTURE_WIDTH] = @((NSInteger) picture.size.width);
			message[FMESSAGE_PICTURE_HEIGHT] = @((NSInteger) picture.size.height);
			message[FMESSAGE_PICTURE_MD5] = md5Picture;

			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendVideoMessage:(FObject *)message video:(NSURL *)video view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_VIDEO;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Video message]" groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataVideo = [NSData dataWithContentsOfFile:video.path];
	NSData *cryptedVideo = [Cryptor encryptData:dataVideo groupId:groupId];
	NSString *md5Video = [Checksum md5HashOfData:cryptedVideo];
	NSNumber *duration = [Video duration:video.path];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_video", @"mp4")];
	FIRStorageUploadTask *task = [reference putData:cryptedVideo metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileVideo:link];
			[dataVideo writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_VIDEO] = link;
			message[FMESSAGE_VIDEO_DURATION] = duration;
			message[FMESSAGE_VIDEO_MD5] = md5Video;

			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendAudioMessage:(FObject *)message audio:(NSString *)audio view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_AUDIO;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Audio message]" groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataAudio = [NSData dataWithContentsOfFile:audio];
	NSData *cryptedAudio = [Cryptor encryptData:dataAudio groupId:groupId];
	NSString *md5Audio = [Checksum md5HashOfData:cryptedAudio];
	NSNumber *duration = [Audio duration:audio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_audio", @"m4a")];
	FIRStorageUploadTask *task = [reference putData:cryptedAudio metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileAudio:link];
			[dataAudio writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_AUDIO] = link;
			message[FMESSAGE_AUDIO_DURATION] = duration;
			message[FMESSAGE_AUDIO_MD5] = md5Audio;

			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendLoactionMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_LOCATION;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Location message]" groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_LATITUDE] = @([Location latitude]);
	message[FMESSAGE_LONGITUDE] = @([Location longitude]);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[message saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[Recent updateLastMessage:message];
			//-------------------------------------------------------------------------------------------------------------------------------------
			if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_STATUS] == NO)
				[Audio playMessageOutgoing];
			//-------------------------------------------------------------------------------------------------------------------------------------
			SendPushNotification1(message);
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
}

@end
