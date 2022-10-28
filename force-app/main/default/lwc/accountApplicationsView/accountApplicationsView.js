/*********************************************************************************************************
*
* Change log:
*

* 
**********************************************************************************************************/
import { LightningElement, wire, track , api} from 'lwc';
import getRecords from "@salesforce/apex/AccountPageHeader.getRecords";
import getTotalRecords from "@salesforce/apex/AccountPageHeader.getTotalRecords";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

const columns = [
    {
        label: 'Opportunity Name',
        fieldName: 'OpportunityUrl',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            },
            target: '_self'
        }
    },
    {
        label: 'Account Name', 
        fieldName: 'AccountUrl', 
        type: 'url',  
        typeAttributes: {
            label: {
                fieldName: 'AccountName'
            }, 
            target: '_self'
        }
   },
    { label: 'Application Number', fieldName: 'Application_Number__c'},
    { 
        label: 'Partner Sales Rep', 
        fieldName: 'salesRepUrl',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'salesRep'
            },
            target: '_self'
        }
    },
    { label: 'Amount', fieldName: 'Amount', type: 'currency', fixedWidth: 100, typeAttributes: { currencyCode: 'USD' }},
    { label: 'Application Date', fieldName: 'Application_Date__c', type: 'date', typeAttributes: {
        day: "numeric",
        month: "numeric",
        year: "numeric"
    } },
    { label: 'Sub-Stage', fieldName: 'Sub_Stage__c'}
];

export default class accountApplicationView extends LightningElement {
    @api recordId;
    name;
    accountNumber;
    industry;
    accountId;

    opportunities = [];
    totalNumberOfRows;
    error;
    columns = columns;
    sortBy;
    sortDirection;
    rowLimit = 20;
    rowOffset = 0;
    loadMoreStatus;
    applicationDate='';
    applicationDatePickListValues =[];
    partnerStatus='';
    searchAllValue ='';
    enableInfiniteLoading = true;
    initialDataLoaded = false;   
    datatable;
    itemCount;
    now= Date.now();
    saleRapOptions;
    saleRapValue='';
    errorMsg='';
    
    @wire(CurrentPageReference)
    getpageRef(pageRef) {
        console.log('data => ', JSON.stringify(pageRef));
        this.recordId = pageRef.attributes.recordId;
    }
    

    connectedCallback() {
        this.getInitialOpportunities();
    }

    getInitialOpportunities() {

        getRecords({
            accountId: this.recordId,
            rowLimit: this.rowLimit,
            rowOffset: this.rowOffset,
        }).then(result => {
            console.log(result);
            if (result) {
                let tempOpportunitiesList = [];
                result.forEach((record) => {
                    let tempOpportunity = Object.assign({}, record);
 
                    if(tempOpportunity.Account){
                        tempOpportunity.AccountName = tempOpportunity.Account.Name;
                        tempOpportunity.AccountUrl = window.location.origin + '/dllondemand/s/account/' + tempOpportunity.AccountId;
                    } else {
                        tempOpportunity.AccountName = '';
                    }

                    tempOpportunity.Name = tempOpportunity.Name;
                    tempOpportunity.OpportunityUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempOpportunity.Id;
                    
                    
                    if (tempOpportunity.Partner_Sales_Rep__r){
                        tempOpportunity.salesRep = tempOpportunity.Partner_Sales_Rep__r.Name;
                        tempOpportunity.salesRepUrl = window.location.origin + '/dllondemand/s/detail/' + tempOpportunity.Partner_Sales_Rep__r.Id;
                    } else {
                        tempOpportunity.salesRep = '';
                    }

                    tempOpportunitiesList.push(tempOpportunity);
                    console.log('oppList:' + tempOpportunitiesList);


                });

                this.opportunities = tempOpportunitiesList;
                getTotalRecords({accountId: this.recordId}).then(result => {
                    console.log(result);
                    if (result) {
                        console.log(result + 'Newt');
                        this.totalNumberOfRows = result;
                        this.initialDataLoaded = true;
                        if(this.totalNumberOfRows > this.rowLimit){
                            this.itemCount = this.rowLimit + '+';
                        }
                        else{
                            this.itemCount = this.totalNumberOfRows;
                        }
                    }

                })
            } else if (result.error) {
                this.initialDataLoaded = true;
                console.error("Error", error);
            }
        })

    }

    // Event to handle onloadmore on lightning datatable markup
    loadMoreData(event) {
        event.preventDefault();
        console.log('data loading oppview');
        this.datatable = event.target;
        if (this.initialDataLoaded) {
            this.enableInfiniteLoading =true;
            this.datatable.isLoading = true;
            this.loadMoreStatus = 'Loading';
            this.rowOffset = this.rowLimit + this.rowOffset;

            if (this.rowOffset <= this.totalNumberOfRows) {
                getRecords({
                    accountId: this.recordId,
                    rowLimit: this.rowLimit,
                    rowOffset: this.rowOffset,
                }).then(result => {
                        console.log(result);
                        let tempMoreOpportunitiesList = [];
                        result.forEach((record) => {
                            let tempMoreOpportunity = Object.assign({}, record);

                            if(tempMoreOpportunity.Account){
                                tempMoreOpportunity.AccountName = tempMoreOpportunity.Account.Name;
                                tempMoreOpportunity.AccountUrl = window.location.origin + '/dllondemand/s/account/' + tempMoreOpportunity.AccountId;
                            } else {
                                tempMoreOpportunity.AccountName = '';
                            }
        
                            tempMoreOpportunity.Name = tempMoreOpportunity.Name;
                            tempMoreOpportunity.OpportunityUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempMoreOpportunity.Id;
                            
                            
                            if (tempMoreOpportunity.Partner_Sales_Rep__r){
                                tempMoreOpportunity.salesRep = tempMoreOpportunity.Partner_Sales_Rep__r.Name;
                                tempMoreOpportunity.salesRepUrl = window.location.origin + '/dllondemand/s/detail/' + tempMoreOpportunity.Partner_Sales_Rep__r.Id;
                            } else {
                                tempMoreOpportunity.salesRep = '';
                            }
    
                            tempMoreOpportunitiesList.push(tempMoreOpportunity);
                        });
                        this.opportunities = this.opportunities.concat(tempMoreOpportunitiesList);
                        this.loadMoreStatus = '';
                        this.datatable.isLoading = false;
                        this.itemCount = this.rowOffset + '+';
                    }
                );
            } else {
                this.enableInfiniteLoading = false;
                this.datatable.isLoading = false;
                this.loadMoreStatus = 'No more data to load';
                this.itemCount = this.totalNumberOfRows;
            }
        }
    }
}