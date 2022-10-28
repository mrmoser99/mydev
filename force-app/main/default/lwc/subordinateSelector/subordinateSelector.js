import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class SubordinateSelector extends LightningElement {
    @api subordinates;
    @api selectedUserId;
    userOptions;
    isDisabled = true;

    connectedCallback() {
        this.getUserOptions();
    }

    // set options for combobox with users
    getUserOptions() {
        let options = [];
        (JSON.parse(this.subordinates)).forEach(item => {
            options.push({
                value: item.Id,
                label: item.Full_Name__c
            });
        });

        this.userOptions = options;
    }

    // handle user selection
    handleUserChange(event) {
        this.selectedUserId = event.target.value;
        this.isDisabled = false;
    }

    // handle custom flow navigation: BACK button
    handleBackBtn() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    // handle custom flow navigation: NEXT button
    handleNextBtn() {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}