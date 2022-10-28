/*********************************************************************************************************
*
* Change log:
*
* 
**********************************************************************************************************/
import { LightningElement, wire, track , api} from 'lwc';
import getRecords from "@salesforce/apex/ContractListView.getRecords";
import getTotalRecords from "@salesforce/apex/ContractListView.getTotalRecords";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

const columns = [
    {
        label: 'Contract Number',
        fieldName: 'contractUrl',
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
    { label: 'Finance Type', fieldName: 'Finance_Type__c'},
    { label: 'Contract Term (months)', fieldName: 'Contract_Term_months__c'},
    { label: 'Payments Remaining', fieldName: 'Payments_Remaining__c'},
    { label: 'Health', fieldName: 'Health__c'},
    { label: 'Status', fieldName: 'Status_Text__c'},
    { label: 'Program', fieldName: 'program'}

];

export default class contractListView extends LightningElement {
    @api recordId;
    name;
    accountNumber;
    industry;
    accountId;

    contracts = [];//opportunities = [];
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
        this.getInitialContracts();
    }

    getInitialContracts() {

        getRecords({
            accountId: this.recordId,
            rowLimit: this.rowLimit,
            rowOffset: this.rowOffset,
        }).then(result => {
            console.log('Fernando' + result);
            if (result) {
                let tempContractsList = [];
                result.forEach((record) => {
                    let tempContracts = Object.assign({}, record);

                    tempContracts.Name = tempContracts.Name;
                    tempContracts.contractUrl = window.location.origin + '/dllondemand/s/contract/' + tempContracts.Id;

                    if (tempContracts.Program__r){
                        tempContracts.program = tempContracts.Program__r.Name;
                    } else {
                        tempContracts.program = '';
                    }
                    
                    if (tempContracts.Account__r){
                        tempContracts.AccountName = tempContracts.Account__r.Name;
                        tempContracts.AccountUrl = window.location.origin + '/dllondemand/s/account/' + tempContracts.Account__r.Id;
                    } else {
                        tempContracts.AccountName = '';
                    }                                       
                    
                    if (tempContracts.Partner_Sales_Rep__r){
                        tempContracts.salesRep = tempContracts.Partner_Sales_Rep__r.Name;
                        tempContracts.salesRepUrl = window.location.origin + '/dllondemand/s/detail/' + tempContracts.Partner_Sales_Rep__r.Id;
                    } else {
                        tempContracts.salesRep = '';
                    }

                    tempContractsList.push(tempContracts);
                    console.log('oppList:' + tempContractsList);


                });

                this.contracts = tempContractsList;
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
        }).catch(e => console.log('Fernando ' +JSON.stringify(e)));

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
                    accountId: this.accountId,
                    rowLimit: this.rowLimit,
                    rowOffset: this.rowOffset,
                }).then(result => {
                        console.log(result);
                        let tempMoreContractList = [];
                        result.forEach((record) => {
                            let tempMoreContract = Object.assign({}, record);  
                        });
                        this.contracts = this.contracts.concat(tempMoreContractList);
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