import { LightningElement, track } from 'lwc';
import deleteOpp from '@salesforce/apex/QuoteListView.deleteOpp';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getTop5Quotes from '@salesforce/apex/QuoteListView.getTop5Quotes'; 
import refreshDashboard from '@salesforce/apex/QuoteListView.refreshDashboard';
import {NavigationMixin} from 'lightning/navigation';

//Declare constants
const actions = [{
    label: 'Delete',
    name: 'delete'
}, {
    label: 'Edit',
    name: 'edit'
}];

const columns = [{
    label: 'Quote Number',
    fieldName: 'QuoteNumberURL',
    type: 'url',
    sortable: true,
    typeAttributes: {
        label: {
            fieldName: 'Qnumber'
        },
        target: '_self'
    }
},
{
    label: 'Customer',
    fieldName: 'EndUserURL',
    type: 'url',
    sortable: true,
    typeAttributes: {
        label: {
            fieldName: 'endUserName'
        },
        target: '_self'
    }
},
{
    label: 'Creator',
    fieldName: 'createdbyname',
    type: 'text',
    sortable: true,
    typeAttributes: {
        label: {
            fieldName: 'CreatedBy.Name'
        }
    }
},
{
    label: 'Nickname',
    fieldName: 'nickName',
    type: 'text',
    sortable: true
},
{
    label: 'Sales Rep',
    fieldName: '',
    type: 'text',
    sortable: true
},
{
    label: 'Date Created',
    fieldName: 'CreatedDate',
    type: 'date-local',
    typeAttributes: {
        month: "2-digit",
        day: "2-digit"
    },
    sortable: true
},
{
    label: 'Last Modified',
    fieldName: 'lastModifiedDate',
    type: 'date-local',
    typeAttributes: {
        month: "2-digit",
        day: "2-digit"
    },
    sortable: true
},
{
    label: 'Status',
    fieldName: 'substage',
    type: 'text',
    sortable: true
},
{
    label: '',
    type: 'action',
    typeAttributes: {
        rowActions: actions
    }
}
];
export default class HomeQuoteListView extends NavigationMixin(LightningElement) {

    @track quotes = [];
    columns = columns;

    connectedCallback() {

        refreshDashboard();
        
        getTop5Quotes({

        })
        .then(result=>{
            console.log(result);
           this.quotes = result.map(res=>{
            let tempOpportunity = {...res} ;



            //create temp variable createdbyname
            if (tempOpportunity.CreatedBy.Name != null) {
               tempOpportunity.createdbyname = tempOpportunity.CreatedBy.FirstName + ' ' + tempOpportunity.CreatedBy.LastName;
           }
   
            //create temp variable QuoteNumberURL
            if (tempOpportunity.Opportunity_Number__c == undefined) {
               tempOpportunity.QuoteNumberURL = '#';
               tempOpportunity.Qnumber = '#';
           } else {
               tempOpportunity.QuoteNumberURL = window.location.origin + '/dllondemand/s/new-quote?oppid=' + tempOpportunity.Id;
               tempOpportunity.Qnumber = tempOpportunity.Opportunity_Number__c;
            }

           //create temp variable endUserName
           if (tempOpportunity.End_User__r) {
               console.log('enduser name ' + tempOpportunity.End_User__r.Name);
               tempOpportunity.endUserName = tempOpportunity.End_User__r.Name;
           } else {
               tempOpportunity.endUserName = 'Unknown';
           }

           //create temp variable nickName
           if (tempOpportunity.Nickname__c) {
                tempOpportunity.nickName = tempOpportunity.Nickname__c;
            } else {
                tempOpportunity.nickName = 'Unknown';
            }

            //create temp variable CreatedDate
           if (tempOpportunity.CreatedDate) {
            tempOpportunity.CreatedDate = tempOpportunity.CreatedDate;
            } else {
            tempOpportunity.CreatedDate = 'Unknown';
             }


            //create temp variable LastModifiedDate
           if (tempOpportunity.LastModifiedDate) {
            tempOpportunity.lastModifiedDate = tempOpportunity.LastModifiedDate;
            } else {
            tempOpportunity.lastModifiedDate = 'Unknown';
             }  

          
              //create temp variable substage
           if (tempOpportunity.Sub_Stage__c) {
            tempOpportunity.substage = tempOpportunity.Sub_Stage__c;
            } else {
            tempOpportunity.substage = 'Unknown';
             }  

           //create temp variable EndUserURL
           if (tempOpportunity.End_User__c == undefined) {
               tempOpportunity.EndUserURL = '#';
           } else {
               tempOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempOpportunity.End_User__c;
           }
   
           return tempOpportunity;
           });
        

            
        })
        .catch(error=>{
            console.log(JSON.stringify(error));
        });
       
    }
    
    processmyresultfunction(res){


    }
    
    
    
    //Display toast
     showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }
    



    

        //Method to handle Row action event - edit and delete
        handleRowAction(event) {
            this.loader = true;
            const actionName = event.detail.action.name;
            const row = event.detail.row;
    
            if (actionName === 'delete') {
    
                deleteOpp({
                    oppId: row.Id
                }).then(result => {
    
                    this.loader = false;
                    this.connectedCallback();
                    this.showToast('Quote deleted Successfully', result, 'success');
    
                }).catch(error => {
                    console.log('error' + JSON.stringify(error));
                    this.loader = false;
                })
    
            }
            if (actionName === 'edit') {
                console.log('rowid ' +row.Id);
                this.loader = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: window.location.origin + '/dllondemand/s/new-quote?oppid=' + row.Id
                    }
                })
            }
    
        }

}