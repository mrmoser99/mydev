import { LightningElement,api,track } from 'lwc';
import {showPopUpNotification, screenNamesTR, quoteStatuses, constants } from 'c/ldsUtils';

export default class ProgressiveBar extends LightningElement {
    screenNamesTR = screenNamesTR;
    quoteStatuses = quoteStatuses;
    labels = constants;
    @api stages = [this.labels.Calculation, this.labels.Customer, this.labels.Documents, this.labels.E_Sign,this.labels.Review];
    @api currentQuoteStage = ''; //to hold quote stage
    @api oppname;
    @track _restquotename;
    @track _latestqtnme = '';
    restQuoteNameLst_clone = [];
    @track value = '';
    currentQuoteId = '';
    stepNametoNumberObj;
    showHideCopy = 'display: none';
    @track isDsabled = true;
    @api currentScreen;
    @track maximumScreenNavigation = 1; //to store the maximum screen allowed navigation for the user
    @api showReviewScreen;
    _showSyncedQuote;
    @api partnerInfo;

    connectedCallback() {
        // Set key-value pairs to the stepNametoNumberObj object. 
        // Screen name is the key, screen number is the value
        let stepNametoNumberObj = {};
        this.stages.forEach((item, index) => {
            stepNametoNumberObj[item] = ++index;
        });
        this.stepNametoNumberObj = stepNametoNumberObj;
    }

    @api 
    get showSyncedQuote(){
        return this._showSyncedQuote;
    }

    set showSyncedQuote(value){
        this._showSyncedQuote = value;
        
    }

    @api
    get restquotename() {       
        return this._restquotename;
    }

    set restquotename(value) {      
        this._restquotename = JSON.parse(value);
        // if list length is greater than zero, then show copy option
        if(this._restquotename.length > 0 && Array.isArray(this._restquotename)){
            this.showHideCopy = 'display: block'; 
            this.isDsabled = false;
            this.restQuoteNameLst_clone = this._restquotename;      
            
            if(this._showSyncedQuote){
                const foundSyncedQuote = this._restquotename.find(element => element.label.includes('★')); //always find the synced quote and open it
                this.value = foundSyncedQuote.value; 
                this.currentQuoteId = foundSyncedQuote.qid; 
            }else{
                this.value = this._restquotename[0].value;  
                this.currentQuoteId = this._restquotename[0].qid; 
            }    
        }   
    }

    @api 
    get latestqtnme(){
        return this._latestqtnme;
    }

    set latestqtnme(value){       
        this._latestqtnme = value;      
    }

    /** Method checks last available step according current quote status 
     *  and sets its number it as maximumScreenNavigation value
     * 
     * @return String last available screen name
     */
    get lastAvaliableScreen() {
        switch (this.currentQuoteStage) {
            case this.quoteStatuses.Calculation:
            case this.quoteStatuses.Assessment:
            case this.quoteStatuses.Declined:
            case this.quoteStatuses.Refer:
            case this.quoteStatuses.BlockedDueToMultiplePG:
                this.maximumScreenNavigation = 2;
                return this.labels.Customer;
            case this.quoteStatuses.Approved:
            case this.quoteStatuses.ApprovedWithConditions:    
                this.maximumScreenNavigation = 3;
                return this.labels.Documents;
            case this.quoteStatuses.DocumentsGenerated:
            case this.quoteStatuses.PendingESign:
            case this.quoteStatuses.PendingDocumentation:
            case this.quoteStatuses.PendingValidation:
            case this.quoteStatuses.PendingInformation:
            case this.quoteStatuses.PendingReview:
            case this.quoteStatuses.ReviewCompleted:
                if(!this.showReviewScreen){
                    this.maximumScreenNavigation = 4;
                    return this.labels.E_Sign;
                }else{
                    this.maximumScreenNavigation = 5;
                    return this.labels.Review;
                }
            default:
                this.maximumScreenNavigation = 1;
                return this.labels.Calculation;
        }
    }
    /**method to find if a value is valid or not */
    isNullOrZeroOrUndefined(value) {
        return value == null || value == undefined || value == 0 || value == '';
    }

    /**method to disable the new version button if no quote is present on a opportunity or quote status is Review Completed*/
    get disableNewButton(){
        if(this.isNullOrZeroOrUndefined(this.currentQuoteStage) || this.currentQuoteStage === this.quoteStatuses.ReviewCompleted){
            return true;
        }
    }

    /**method to disable the QuoteSettingMenu if quote status is Review Completed */
    get disableQuoteSettingMenu() {
        if (this.currentQuoteStage === this.quoteStatuses.ReviewCompleted) {
            // to disable the combobox with quote version if quote status is Review Completed
            this.isDsabled = true;
            return true;
        }
    }

    /** Method dispatches blank event when user clicks on New version button */
    handleNewVersion(event){
        //dispatch blank event for new version puropse handled in parent component
        const selectEvent = new CustomEvent('clicknewversion', {
            detail: ''
        });
        this.dispatchEvent(selectEvent);
    }

    /** Method dispatches blank event when user changes the quote picklist values */
    handleChangeQuoteDropdwn(event){
        const selQuoteName = event.detail.value;
        this.value = event.detail.value;
        //get the index of the selectedvalue from the array
        const QtNameIndex = this.restQuoteNameLst_clone.map(function(e) { return e.value; }).indexOf(selQuoteName);              
        //get the whole object details of the last quote name from the array
        let QtNameObj = this.restQuoteNameLst_clone[QtNameIndex];      
        this.currentQuoteId = QtNameObj.qid;

        //dispatch event on change of quote name to parent component to show the quote details
        const selectEvent = new CustomEvent('changequotename', {
            detail: QtNameObj.qid
        });
        this.dispatchEvent(selectEvent);
    }

    /** When user clicks on progress steps  */
    handleProgressStepClick(event){
        let userClickedStepNum = this.stepNametoNumberObj[event.target.value];

        if (userClickedStepNum > this.maximumScreenNavigation) {
            // if user click on the unavailable step show notification in the top of the page
            showPopUpNotification(this, `${this.labels.Invalid_Step} ${event.target.value}`, 'error');
        } else if (
                userClickedStepNum < this.maximumScreenNavigation || 
                (userClickedStepNum = this.maximumScreenNavigation && userClickedStepNum != this.stepNametoNumberObj[this.currentScreen])
            ) {
            // dispatch event if user click on the step which is less then maximumScreenNavigation and not equal to current step

            for (let prop in this.screenNamesTR) {
                if (this.screenNamesTR[prop] === event.target.value) {
                 
                    const selectEvent = new CustomEvent('changeprogrestep', {
                        detail: prop //event.target.value
                    });
                    this.dispatchEvent(selectEvent);
                    break;
                }
            }
        }
    }

    /** When user clicks on copy quote dropdown value */
    handleCopyQuote(event){
        const selectedQuoteName = this.value;
        //get the index of the selectedvalue from the array
        const QtNameIndex = this.restQuoteNameLst_clone.map(function(e) { return e.value; }).indexOf(selectedQuoteName);              
        //get the whole object details of the last quote name from the array
        let QtNameObj = this.restQuoteNameLst_clone[QtNameIndex];      
        this.currentQuoteId = QtNameObj.qid;
        //dispatch event on click of Copy quote dropdown
        const selectEvent = new CustomEvent('copyquoteevent', {
            detail: QtNameObj.qid
        });
        this.dispatchEvent(selectEvent);
    }

}