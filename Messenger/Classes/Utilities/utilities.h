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

#ifndef app_utilities_h
#define app_utilities_h

#import <AVKit/AVKit.h>
#import <Contacts/Contacts.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MobileCoreServices/MobileCoreServices.h>

#pragma mark -

#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <Firebase/Firebase.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <OneSignal/OneSignal.h>
#import <Realm/Realm.h>
#import <Sinch/Sinch.h>
#import <SinchVerification/SinchVerification.h>

#pragma mark -

#import "IQAudioRecorderViewController.h"
#import "JSQMessages.h"
#import "MBProgressHUD.h"
#import "MGSwipeTableCell.h"
#import "NYTPhotoViewer.h"
#import "ProgressHUD.h"
#import "Reachability.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "SinchService.h"

#pragma mark -

#import "AppConstant.h"

#pragma mark - advert

#import "advert.h"

#pragma mark - backend1

#import "FObject.h"
#import "FUser.h"
#import "FUser+Util.h"
#import "NSError+Util.h"

#pragma mark - backend2

#import "Blockeds.h"
#import "CallHistories.h"
#import "Contacts.h"
#import "Groups.h"
#import "Messages.h"
#import "Recents.h"
#import "Users.h"
#import "UserStatuses.h"

#pragma mark - backend3

#import "Account.h"
#import "Blocked.h"
#import "CallHistory.h"
#import "Chat.h"
#import "Group.h"
#import "Message.h"
#import "Recent.h"

#pragma mark - backend4

#import "push.h"
#import "user.h"

#pragma mark - general1

#import "NotificationCenter.h"
#import "NSDate+Util.h"
#import "NSDictionary+Util.h"
#import "UserDefaults.h"

#pragma mark - general2

#import "Connection.h"
#import "Location.h"

#pragma mark - general3

#import "Audio.h"
#import "Checksum.h"
#import "Cryptor.h"	
#import "Dir.h"
#import "Emoji.h"
#import "File.h"
#import "Image.h"
#import "Password.h"
#import "Shortcut.h"
#import "Video.h"

#pragma mark - general4

#import "camera.h"
#import "common.h"
#import "converter.h"

#pragma mark - manager

#import "AlbumManager.h"
#import "CacheManager.h"
#import "DownloadManager.h"
#import "MediaManager.h"
#import "RealmManager.h"

#pragma mark - mediaitems

#import "Incoming.h"
#import "AudioMediaItem.h"
#import "EmojiMediaItem.h"
#import "PhotoMediaItem.h"
#import "VideoMediaItem.h"

#pragma mark - messages

#import "MessageForward.h"
#import "MessageQueue.h"
#import "MessageSend1.h"
#import "MessageSend2.h"

#pragma mark - other

#import "NYTPhotoItem.h"

#pragma mark - realm

#import "DBBlocked.h"
#import "DBCallHistory.h"
#import "DBContact.h"
#import "DBGroup.h"
#import "DBMessage.h"
#import "DBRecent.h"
#import "DBUser.h"
#import "DBUserStatus.h"

#endif
