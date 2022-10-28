import { LightningElement, api } from 'lwc';
import { constants } from 'c/ldsUtils';

export default class PopUpNotificationCmp extends LightningElement {
    labels = constants;
    iconName
    message;
    showMessage;
    variant;
    @api isNotificationStatic;

    /** show notidication and hide it in n sec (n is value in ms) */
   @api showNotification(message, variant) {
       // set notification icon, message and variant ('info', 'error', 'success')
        this.message        = message;
        this.variant        = variant;
        this.iconName       = '#' + variant;
        
        if (!this.isNotificationStatic) {
            this.variant += ' slds-is-absolute';
            // scroll to the top of the page. so user can see the notification
            window.scrollTo({ top: 0, behavior: 'smooth' });
            // hide notification in 30 sec
            setTimeout(this.hideNotification.bind(this), Number(this.labels.Display_Time_For_Pop_Up_Notification));
        }

        // show div with notification
        this.showMessage    = true;
    }

    /** hide div with notification in n sec */
    @api hideNotification() {
        this.showMessage    = false;
    }
}