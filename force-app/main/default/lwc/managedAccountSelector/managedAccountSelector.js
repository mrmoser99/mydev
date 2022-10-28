import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class ManagedAccountSelector extends LightningElement {
    @api managedAccounts;
    @api selectedAccountId;
    accountOptions;
    isDisabled = true;

    connectedCallback() {
        this.getAccountsInfo();
    }

    // set options for combobox with accounts
    getAccountsInfo() {
        let options = [];
        JSON.parse(this.managedAccounts).forEach(item => {
            options.push({
                value: item.AccountId,
                label: item.Account.Name
            });
        });

        this.accountOptions = options;
    }

    // handle account selection
    handleAccountChange(event) {
        this.selectedAccountId = event.target.value;
        this.isDisabled = false;
    }

    // handle custom flow navigation: NEXT button
    handleNextBtn() {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}