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

#import "WelcomeView.h"
#import "LoginPhoneView.h"
#import "LoginGoogleView.h"
#import "LoginEmailView.h"
#import "RegisterEmailView.h"
#import "NavigationController.h"

@implementation WelcomeView

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
}

#pragma mark - Phone login methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionLoginPhone:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertCustom(self);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didLoginPhone
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:^{
		UserLoggedIn(LOGIN_PHONE);
	}];
}

#pragma mark - Google login methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionLoginGoogle:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	LoginGoogleView *loginGoogleView = [[LoginGoogleView alloc] init];
	loginGoogleView.delegate = self;
	[self presentViewController:loginGoogleView animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didLoginGoogle
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:^{
		UserLoggedIn(LOGIN_GOOGLE);
	}];
}

#pragma mark - Facebook login methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionLoginFacebook:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD show:nil Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self signInWithFacebook:^(FUser *user, NSError *error)
	{
		if (error == nil)
		{
			if (user != nil)
			{
				[self dismissViewControllerAnimated:YES completion:^{
					UserLoggedIn(LOGIN_FACEBOOK);
				}];
			}
			else [ProgressHUD dismiss];
		}
		else [ProgressHUD showError:[error description]];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)signInWithFacebook:(void (^)(FUser *user, NSError *error))completion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
	NSArray *permissions = @[@"public_profile", @"email", @"user_friends"];
	[login logInWithReadPermissions:permissions fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error)
	{
		if (error == nil)
		{
			if (result.isCancelled == NO)
			{
				NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
				FIRAuthCredential *credential = [FIRFacebookAuthProvider credentialWithAccessToken:accessToken];
				[FUser signInWithCredential:credential completion:completion];
			}
			else if (completion != nil) completion(nil, nil);
		}
		else if (completion != nil) completion(nil, error);
	}];
}

#pragma mark - Email login methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionLoginEmail:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	LoginEmailView *loginEmailView = [[LoginEmailView alloc] init];
	loginEmailView.delegate = self;
	[self presentViewController:loginEmailView animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didLoginEmail
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:^{
		UserLoggedIn(LOGIN_EMAIL);
	}];
}

#pragma mark - Email register methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionRegisterEmail:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RegisterEmailView *registerEmailView = [[RegisterEmailView alloc] init];
	registerEmailView.delegate = self;
	[self presentViewController:registerEmailView animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didRegisterUser
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:^{
		UserLoggedIn(LOGIN_EMAIL);
	}];
}

@end
