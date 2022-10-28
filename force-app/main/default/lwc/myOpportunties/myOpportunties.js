import { LightningElement,track } from 'lwc';
import { constants,quoteStatuses } from 'c/ldsUtils';
import getMyOpportunties from '@salesforce/apex/QuoteSetupController.getMyOpportunties';

export default class MyOpportunties extends LightningElement {
    
    customLabel = constants;
    quoteStatuses = quoteStatuses;
    @track oppData = []; //to hold the oppty data on screen
    noOpptyFound = false; //boolean to check if any oppty exist or not
    viewAllUrl = ''; //to navigate the page to list view on click of view all link  
       
    oppColumns = [
		{ Translatedlabel : this.customLabel.Deal, label : 'Reference', fieldName : "deal", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small', /*width: 'padding-left: 1%'*/},     
        { Translatedlabel : this.customLabel.Customer, label : 'Customer', fieldName : "customer", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small slds-size--1-of-6',},   
        {Translatedlabel : this.customLabel.Rent,  label : 'Rent', fieldName : "rent", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small slds-size--1-of-12', /*width: 'padding-left: 3%;'*/},  
        {Translatedlabel : this.customLabel.financed_Amount,  label : 'Financed Amount', fieldName : "financedamount", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small slds-size--1-of-6', /*width : 'width: 6rem;'*/},
        { Translatedlabel : this.customLabel.term, label : 'Term', fieldName : "term", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small slds-size--1-of-12', /*'width: 7%'*/},     
        { Translatedlabel : this.customLabel.Status, label : 'Status', fieldName : "status", display : "lwc.output", source : "text", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small',},     
        { Translatedlabel : this.customLabel.Expires, label : 'Expires', fieldName : "creditexpdate", display : "lwc.output", source : "date", schema : "" , icon : "", objKey : "", editable: false, required: false, class: 'slds-p-right_small',},
        { Translatedlabel : this.customLabel.Last_Changed, label : 'Last Changed', fieldName : "lastchanged", display : "lwc.output", source : "date", schema : "" , icon : "", objKey : "", editable: false, required: false,}
        
    ];

    connectedCallback(){       
        
        getMyOpportunties({
            ownerId : ''
        })
        .then(result => {   
            if(result){             
                this.formOpptyData(result);
                this.viewAllUrl = `${window.location.origin}/partners/s/recordlist/Opportunity/Default`
            }           
        })
        .catch(error => {
            this.error = error;
            this.oppData = undefined;
        });       
    }

    /**
     * Create the Opportunity table data.
     */
    formOpptyData(result){       
        let opptyCls = result['oppClsList'];
        if(opptyCls.length == 0){ //if no opptys are found then return
            this.noOpptyFound = true;
            return;
        }
        let counter = 1;
        for(let eachOpp in opptyCls){           
            const newOppobj = {
                uid : counter,
                deal : opptyCls[eachOpp]['opptyName'],
                dealid : opptyCls[eachOpp]['opptyId'],
                customer : opptyCls[eachOpp]['customer'],
                rent : opptyCls[eachOpp]['rent'],
                financedamount : opptyCls[eachOpp]['financedAmount'],
                status : this.translateQuoteStatus(opptyCls[eachOpp]['status']), //translate the status
                term : opptyCls[eachOpp]['term'],
                lastchanged : opptyCls[eachOpp]['lastmodifieddate'],
                creditexpdate : opptyCls[eachOpp]['creditExpDate']
            }
            counter++;
            
            this.oppData.push(newOppobj); 
            
        }
    }

    //translate the statuses
    translateQuoteStatus(status){      
        if(status == this.quoteStatuses.Approved){
            return this.customLabel.Approved_Quote_Status;
        }else if(status == this.quoteStatuses.ApprovedWithConditions){
            return this.customLabel.Approved_With_Conditions;
        }else if(status == this.quoteStatuses.Assessment){
            return this.customLabel.Assessment;
        }else if(status == this.quoteStatuses.Calculation){
            return this.customLabel.Calculation;
        }else if(status == this.quoteStatuses.Declined){
            return this.customLabel.Declined_Quote_Status;
        }else if(status == this.quoteStatuses.DocumentsGenerated){
            return this.customLabel.Documents_Generated;
        }else if(status == this.quoteStatuses.Expired){
            return this.customLabel.Expired_E_Sing_Status;
        }else if(status == this.quoteStatuses.PendingDocumentation){
            return this.customLabel.Pending_Documentation;
        }else if(status == this.quoteStatuses.PendingValidation){
            return this.customLabel.Pending_Validation;
        }else if(status == this.quoteStatuses.PendingInformation){
            return this.customLabel.Pending_Information;
        }else if(status == this.quoteStatuses.PendingESign){
            return this.customLabel.Pending_E_Sign_Quote_Status;
        }else if(status == this.quoteStatuses.PendingReview){
            return this.customLabel.Pending_Review;
        }else if(status == this.quoteStatuses.Refer){
            return this.customLabel.Refer_Quote_Status;
        }else if(status == this.quoteStatuses.ReviewCompleted){
            return this.customLabel.Review_Completed;
        }
    }
}