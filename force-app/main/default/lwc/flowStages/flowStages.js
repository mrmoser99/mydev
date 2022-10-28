import { LightningElement, api,track} from 'lwc';
import { constants, quoteStatuses, screenNamesEN,frequency} from 'c/ldsUtils';

export default class FlowStages extends LightningElement {

    labels = constants;
    quoteStatuses = quoteStatuses;
    screenNamesEN = screenNamesEN;
    frequency = frequency;
    @api currentScreen;             // Input: Current quotestage
    @api totalFinanceAmount = 0;
    @api insurancePerFrqncy = 0;
    @api totalrentalprice = 0;
    @api totalAccumulatedService = 0;
    @api finalBaseRate;
    @api monthlyAmount = '$ 1234.00';     // will be counted in the parent [c-quote-calculator]
    @api isNavigationMenu;
    @api showSpinner;
    @api currentQuoteStage;
    @api enableReviewButton;
    @api offerCurrency;
    @api enableSelectCustomerButton;
    @api offerData;
    @api enableAssessmentButton;
    disabledButtonTitle;
    @api disabledDueToUnavailibleProduct;
    @api viewRentPerMonth = false;
    @api totalPurchaseOptionAmount;
    @api isPurchaseOptionApplicable;
    @api downpayment;
    @api isdownpayment;

    openModal(event){      
        this.template.querySelector('[data-id="myModal"]').classList.add('modalblock');
    }
    closemodal(){      
        this.template.querySelector('[data-id="myModal"]').classList.remove('modalblock');
        this.template.querySelector('[data-id="myModal"]').classList.add('modalhide');
    }

    /* set a label depending on the stage*/
    get buttonLabel() {
        switch (this.currentScreen) {
            case this.screenNamesEN.Calculation:
                return this.labels.select_Customer;
            case this.screenNamesEN.Customer:
                return this.labels.Assessment;
            case this.screenNamesEN.Documents:
                return this.labels.create_Contract;
            case this.screenNamesEN.ESign:
                return this.labels.Review;
            case this.screenNamesEN.Review:
                return this.labels.complete_Button;       
            default:
                console.error('No such stage exists');
        }
    }

    /**
     * Get frequency label
     */
     get frequencyLabel(){
        if (this.viewRentPerMonth) {
			return this.labels.Month;
		} else {
            switch (this.offerData.frequency) {
                case this.frequency.Monthly:
                    return this.labels.Month;
                case this.frequency.Quarterly:
                    return this.labels.Quarter;
                case this.frequency.Semi_Annually:
                    return this.labels.Semi_Annual;
                case this.frequency.Annually:
                    return this.labels.Annual;
                default:
                console.error('No such Frequecny exists');
            }
        }
     }

    /**
     * logic executed whrn clicked on the next button
     */
    handleNextStep(event) {
        //dispatch blank event for save puropse handled in parent comp
        const nextStep = new CustomEvent('nextstep', {
            detail: ''
        });
        this.dispatchEvent(nextStep);
    }
    
    renderedCallback() {
        //get reference to "div" tag and add event listeners. to close modal when user clicks outside anywhere.
        this.template.querySelector('[data-id="myModal"]').addEventListener("click", (e) =>  this.closemodal(), false);  
        this.template.querySelector('[data-id="modalContent"]').addEventListener("click", (e) =>  e.stopPropagation(), false);  
    }

    get isCalcutationScreen() {
        return (this.currentScreen === this.screenNamesEN.Calculation) ? true : false;
    }

    get isNotCalcutationScreen() {
        return (this.currentScreen != this.screenNamesEN.Calculation) ? true : false;
    }

    get isDisabledButton(){
        switch (this.currentQuoteStage) {
            case this.quoteStatuses.PendingESign:
            case this.quoteStatuses.DocumentsGenerated:
            case this.quoteStatuses.ReviewCompleted:
                if (this.currentScreen === this.screenNamesEN.Documents || this.currentScreen === this.screenNamesEN.ESign) {
                    this.disabledButtonTitle = this.labels.review_Button_Help_Text;
                    return this.enableReviewButton ? false : true;
                }
                if (this.currentScreen === this.screenNamesEN.Customer || this.currentScreen === this.screenNamesEN.Calculation || this.currentScreen === this.screenNamesEN.Documents || this.currentScreen === this.screenNamesEN.ESign) {
                    return true;
                }
                break;
            case this.quoteStatuses.Calculation:
            case undefined:
            case '':
                if (this.currentScreen === this.screenNamesEN.Calculation) {
                    this.disabledButtonTitle = this.labels.Financed_Amount_and_Rent_per_month_should_be_calculated;
                    if (this.disabledDueToUnavailibleProduct === true) {
                        return true;
                    }
                    return this.enableSelectCustomerButton ? false : true;
                }
                if (this.currentScreen === this.screenNamesEN.Customer) { //disable assessment button if no customer is selected     
                    this.disabledButtonTitle = '';
                    if (this.disabledDueToUnavailibleProduct === true) {
                        return true;
                    }         
                    return this.enableAssessmentButton ? false : true;
                }
                
                break;
            case this.quoteStatuses.Approved:
            case this.quoteStatuses.PendingDocumentation: 
            case this.quoteStatuses.PendingValidation: 
            case this.quoteStatuses.PendingInformation:
            case this.quoteStatuses.PendingReview:  
            if (this.currentScreen === this.screenNamesEN.Customer || this.currentScreen === this.screenNamesEN.Calculation) {
                return true;
            }
            break;
            default:
                return false;
        }
    }

}