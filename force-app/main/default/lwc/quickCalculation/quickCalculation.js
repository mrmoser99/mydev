import { LightningElement,track} from 'lwc';
import { constants,frequencyTranslated } from 'c/ldsUtils';
import { NavigationMixin } from 'lightning/navigation';
import createOpportunity from '@salesforce/apex/QuoteSetupController.createOpportunity';
import sendCalloutToCalculationApi from '@salesforce/apex/RESTCalloutHelper.sendCalloutToCalculationApi';
import getDetailsForQuickCalculationScreen from '@salesforce/apex/QuoteSetupController.getDetailsForQuickCalculationScreen';

export default class NewDealScreen extends NavigationMixin(LightningElement) {

    @track label = constants;
    frequencyTranslated = frequencyTranslated;
    @track radiovalue = 'amount';
    @track termValue;
    @track amountInput;
    @track isLoading = false;
    @track financeOrRentalAmount = 0;
    @track financeOrPaymentText = '';
    @track paramsForCalculationApi = {}
    @track financeOrRentalAmountFormat = 0;
    @track offerCurrencyCode;
    @track termOptions = [];
    @track stepNum;
    @track maxNum;
    @track minNum;
    @track isDisabledButton = true;
    labelName = '';
    accountid = '';
    currencyVal = '';
    programId;
    applicableOfferId;
    paymentFrequency;
    paymentTiming;
    isValidAmount = false;
    timeOutIdValue;
    CALLOUT_DELAY = 2000; // Wait for 2 second after user stops typing then, perform callout
    financeAmount = 0; //to send to create deal page
    
    
    connectedCallback(){
        this.getOfferDetails();        
    }

    get radioptions() {
        return [
            { label: this.label.amount, value: 'amount',isSelected: this.radiovalue == 'amount'},
            { label: this.label.payment, value: 'payment',isSelected: this.radiovalue == 'payment'},
        ];
    }

    /**get offer details like accountid, currency, payment frequncy*/
    getOfferDetails(){
        //apex callout
        getDetailsForQuickCalculationScreen()
        .then(result => {   
            if(result){               
                this.labelName = result.offerCurency === 'EUR' ? 'Amount (€)' : result.offerCurency === 'USD' ? 'Amount ($)' : result.offerCurency === 'CAD' ? 'Amount ($)' : 'Amount (kr)' ;
                this.currencyVal = result.offerCurency === 'EUR' ? '€ ' : result.offerCurency === 'USD' ? '$ ' : result.offerCurency === 'CAD' ? '$ ' : 'kr ' ;
                this.accountid = result.accountId;
                this.programId = result.programId;
                this.applicableOfferId = result.applicableOfferId;
                this.paymentFrequency = result.offerPaymentFreqncy;
                this.paymentTiming = result.offerPaymentTiming;
                this.offerCurrencyCode = result.offerCurency;   
                let terms = result.offrcls[0].termsOption.split(';');  
                this.termOptions = terms;   
                this.maxNum = this.termOptions[this.termOptions.length - 1];   
                this.termValue = this.termOptions[0];  
                this.minNum = this.termOptions[0];                       
                this.stepNum = this.termOptions[1] - this.termOptions[0];         
            }                    
        })
        .catch(error => {});    
    }

    /*handle the radio button selected value*/
    handleRadioSelected(event) {
        this.radiovalue = event.target.value;
        if(this.radiovalue != undefined && this.radiovalue != null && this.isValidAmount){
            this.handleCalloutToCalculationApi();
        }
     }

     /** handle slider change TERM**/
     handleTermChange(event) {
        this.termValue = event.target.value;

        if(this.termValue != undefined && this.termValue != null && this.isValidAmount){
            this.handleCalloutToCalculationApi();
        }       
    }

    /** 
    *method called when user enter a value in the amount field
    */
    handleAmountChange(e) {
        this.isValidAmount = false;   
        this.amountInput = e.target.value;  
        if(this.amountInput  != undefined && this.amountInput != '' && this.amountInput != 0 && !this.amountInput.includes('-') && this.amountInput >= 1){       
           this.isValidAmount = true;
           //if user types before CALLOUT_DELAY, cancel the callout and again wait for CALLOUT_DELAY.
            if(this.timeOutIdValue != undefined && this.timeOutIdValue){
                clearTimeout(this.timeOutIdValue);
            }
            this.timeOutIdValue = setTimeout(() => {
                this.handleCalloutToCalculationApi(); 
             }, this.CALLOUT_DELAY);              
        }else{
            this.financeOrRentalAmount = 0;
        } 
    }

    /** show notification in the top of the page. The option 'variant' may be 'error' or 'success'*/ 
    showPopUpNotification(message, variant) {
        this.template.querySelector('c-pop-up-notification-cmp').showNotification(message, variant);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    /** Calling Apex to calculation API**/
    handleCalloutToCalculationApi(){
        this.isLoading = true;
        let paramsForCalculation = {
            calculate : this.radiovalue == 'amount' ? 'payments' : 'finance-amount',
            numberOfMonths : this.termValue,
            paymentFrequency : this.paymentFrequency,
            paymentTiming : this.paymentTiming,
            amount: this.amountInput,
            programId: this.programId,
            financialProductId: this.applicableOfferId
        };
        //callout to apex
        sendCalloutToCalculationApi({
            paramsForCalculation : JSON.stringify(paramsForCalculation),
            saveLogsAsync: true
        })
        .then(result => {   
            if (result.errorMessage != '') {
                // handle error here
                this.showPopUpNotification(result.errorMessage,'error');  
                this.isDisabledButton = true;          
            } else {
                let calculate = result.calculate;
                if (calculate == 'payments') {
                    this.financeOrRentalAmount = JSON.stringify(result.rentalAmount);
                    this.financeOrRentalAmount = Math.round(this.financeOrRentalAmount);
                    this.financeOrRentalAmountFormat = new Intl.NumberFormat('en-US').format(this.financeOrRentalAmount); 
                    this.financeAmount = Math.round(this.amountInput); //input Financed Amount when calcualte payment
                    this.financeOrPaymentText =  this.frequencyTranslated[this.paymentFrequency] +' '+this.label.payment;
                } else {
                    this.financeOrRentalAmount = JSON.stringify(result.financeAmount);
                    this.financeOrRentalAmount = Math.round(this.financeOrRentalAmount);
                    this.financeOrRentalAmountFormat = new Intl.NumberFormat('en-US').format(this.financeOrRentalAmount); 
                    this.financeAmount = Math.round(this.financeOrRentalAmount); 
                    this.financeOrPaymentText = this.label.financed_Amount;
                } 
            }              
            this.isLoading = false;
            this.isDisabledButton = false;                         
        })
        .catch(error => {       
            this.isLoading = false;
            this.isDisabledButton = true;
        });  
    }

    //get new deal button class name
    get newDealBtnClassName(){
        //if changeStle is true, getter will return class1 else class2
          return this.isDisabledButton ? 'newDealBtnClass extra-small-text': 'primaryButton extra-small-text';
      }

    /**
     * method called when user clicked on 'Start New deal' button.
     *  call apex to create a opportunity, then pass the oppid to the QuoteCalculator lwc comp.
     */   
     async createNewDeal(event){
        this.isLoading = true;
        this.isDisabledButton = true;   
        var today = new Date();
        today.setDate(today.getDate() + 365);
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = today.getFullYear();
        today = yyyy + '-' + mm + '-' + dd;
        try{
            //creating oppty by calling std sfdc method
            createOpportunity({ 
                amount : 0.0,
                acctid : this.accountid,
                currencyCode : this.offerCurrencyCode
             })
                .then(result => {
                    //only navigate when valid result is returned
                    if(result != 'undefined' && !isNaN(this.financeOrRentalAmount) && this.financeOrRentalAmount != 0 && this.isValidAmount){
                        this.navigateToQuotePage(result);
                    }else{
                        this.isDisabledButton = false;
                        this.showPopUpNotification(
                            this.label.please_enter_valid_input, 
                            'error'
                        );
                    }                       
                })
                .catch(error => {
                    this.isDisabledButton = false;   
                    this.showPopUpNotification(
                        reduceErrors(error), 
                        'error'
                    );
                });
            this.isLoading = false;
        }catch (error) {
            this.isDisabledButton = false;   
            this.isLoading = false;
        }
    }

    /**
     * Navigate to Deal page 
     */
    navigateToQuotePage(oppid){
        this.isLoading = true;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                //pass the opporunity id
                url : `${window.location.origin}/partners/s/quote?oppId=${oppid}&term=${this.termValue}&financeAmount=${this.financeAmount}` 
            }
        }).then(url => {
            window.open(url,"_self");
        });
    }
}