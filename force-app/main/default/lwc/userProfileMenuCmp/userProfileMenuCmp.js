import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
// user Id
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class UserProfileMenuCmp extends NavigationMixin(LightningElement) {
    userSmallPhotoUrl;
    userInitials;
    userAvatar;
    userName;
    clickOutsideMenu;
    isMenuDisplayed = false;

    /** Get information about the user and his avatar */
    @wire(getRecord, { recordId: Id, fields: ['User.FirstName', 'User.LastName','User.Name', 'User.SmallPhotoUrl'] })
    userData({data}) {
        if (data) {
            this.userSmallPhotoUrl  = data.fields.SmallPhotoUrl.value;
            this.userName           = data.fields.Name.value;

            //check whether the avatar is standard or loaded by the user
            this.checkAvatar(data);
        } 
    }

    /** Check if avatar is standard or not. Initials are used if avatar is standard */
    checkAvatar(data) {
        if (this.userSmallPhotoUrl.includes('profilephoto/005/')) {
            //get initials if avatar is standard
            this.userInitials   = data.fields.FirstName.value[0] + data.fields.LastName.value[0];
            this.userAvatar     = undefined;
        } else {
            this.userAvatar     = this.userSmallPhotoUrl;
            this.userInitials   = undefined;
        }
    }

    /** Open and close menu */
    handleMenuDisplay(event) {
        let menu                = this.template.querySelector('.userProfileMenu');
        this.isMenuDisplayed    = !this.isMenuDisplayed;
  
        if (this.isMenuDisplayed) {
            menu.classList.add('slds-is-open');
            //the listener is added to close the menu when clicking outside the menu
            this.addClickEventListener(event);
        } else {
            menu.classList.remove('slds-is-open');
            //listener is deleted when menu is closed
            this.removeClickEventListener();
        } 
    }

    addClickEventListener(event) {
        document.addEventListener('click', this.clickOutsideMenu = this.handleMenuDisplay.bind(this));
        event.stopPropagation();
    }

    removeClickEventListener() {
        document.removeEventListener('click', this.clickOutsideMenu);
    }
    
    navigateToProfilePage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: Id,
                objectApiName: 'Profile',
                actionName: 'view',
            },
        });
    }

    logOut() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'logout'
            }
        });
    }
}