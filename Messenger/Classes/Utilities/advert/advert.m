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

#import "AdvertCustomView.h"
#import "AdvertPremiumView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
void AdvertCustom(id target)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertCustomView *advertCustomView = [[AdvertCustomView alloc] init];
	advertCustomView.modalPresentationStyle = UIModalPresentationOverFullScreen;
	[target presentViewController:advertCustomView animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void AdvertPremium(id target)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertPremiumView *advertPremiumView = [[AdvertPremiumView alloc] init];
	advertPremiumView.modalPresentationStyle = UIModalPresentationOverFullScreen;
	[target presentViewController:advertPremiumView animated:YES completion:nil];
}
