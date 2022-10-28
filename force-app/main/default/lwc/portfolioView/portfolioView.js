/*********************************************************************************************************
* portfolio view - modified code d05
*
* change log:
*
*   10/18/2021 - MRM created
*   04/28/2022 - Geetha added logic for Download Portfolio and ability to filter records based on 
*                filter criteria
* 
**********************************************************************************************************/
import { LightningElement, wire, track , api} from 'lwc';
import getRecords from "@salesforce/apex/PortfolioViewController.getRecords";
import getTotalRecords from "@salesforce/apex/PortfolioViewController.getTotalRecords";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getdownloadRecords from "@salesforce/apex/PortfolioViewController.getdownloadRecords";

const columns = [
    { label: 'Contract', fieldName: 'contractUrl', wrapText:false, sortable: true,
        type: 'url',
        typeAttributes: {label: { fieldName: 'contractNumber' },
            target: '_self'}
    },
    { label: 'Customer Name', fieldName: 'endUserURL', sortable: true,
        type: 'url',
        typeAttributes: {label: { fieldName: 'customerName' },
            target: '_self'}
    },
    { label: 'Sales Rep', fieldName: 'salesRep'},
    { label: 'Finance Type', fieldName: 'financeType', sortable: true},
//    { label: 'Serial(s)', fieldName: 'serials'},
//    { label: 'Make(s)', fieldName: 'makes' },
    { label: 'Term', fieldName: 'term', sortable: true},
    { label: 'Payments Remaining', fieldName: 'remainPay', sortable: true },
    { label: 'Health', fieldName: 'health', sortable: true },
    { label: 'Status', fieldName: 'status', sortable: true  }
    
];

const columns2 = [
    { label: 'Contract', fieldName: 'contractNumber', wrapText:false, /*initialWidth: 200,*/ sortable: true},
    { label: 'Customer Name', fieldName: 'customerName', /*initialWidth: 200,*/ sortable: true },
    { label: 'Sales Rep', fieldName: 'salesRep', /*initialWidth: 200,*/ sortable: true },
    { label: 'Finance Type', fieldName: 'financeType',  /*initialWidth: 110,*/ sortable: true},
//    { label: 'Serial(s)', fieldName: 'serials', /*initialWidth: 150,*/ sortable: true},
//    { label: 'Make(s)', fieldName: 'makes',  /*initialWidth: 150,*/ sortable: true  },
    { label: 'Term', fieldName: 'term', /*initialWidth: 100,*/ sortable: true},
    { label: 'Payments Remaining', fieldName: 'remainPay', /*initialWidth: 100,*/ sortable: true  },
    { label: 'Health', fieldName: 'health', /*initialWidth: 100,*/ sortable: true },
    { label: 'Status', fieldName: 'status', /*initialWidth: 120,*/ sortable: true }
    
];


export default class PortfolioView extends LightningElement {

    refreshExecute = true;
    portfoliolist = [];
    error; 
    columns=columns;
    maxRows=100;
    totalRecords=null;
    offSet=0;
    loadMoreStatus;
    targetDataTable;
    searchDate=0;
    searchStatus='';
    isLoading=true;
    filter;
    savelist;
    totalRecords=0;
    itemCount;
    orderByField;
    orderByDirection;
    downloaddata =[];
        
    datelist = [
        {value: '0', label: 'All Time'},
        {value: 'LAST_N_DAYS:30', label: 'Last 30 Days'},
        {value: 'LAST_N_DAYS:60', label: 'Last 60 Days'},
        {value: 'LAST_N_DAYS:90', label: 'Last 90 Days'},
        {value: 'LAST_N_MONTHS:12', label: 'Last 12 Months'},
        {value: '2021', label: '2021'},
        {value: '2020', label: '2020'},
        {value: '2019', label: '2019'}
    
    ];

    statuslist = [
        {value: 'ALL', label: 'ALL'},
        {value: 'BOOKED', label: 'BOOKED'},
        {value: 'EVERGREEN', label: 'EVERGREEN'},
        {value: 'TERMINATED', label: 'TERMINATED'}
    ];

    /*added header columns for excel- Download Portfolio*/
    headers = {
        customerLegalName : 'Customer Legal Name',
        contractNumber: 'Contract Number',
        assetNumber: 'Asset Number',
        assetOriginalCost: 'Asset Original Cost',
        assetEquipmentPayment: 'Asset Equipment Payment',
        contractOriginalCost: 'Contract Original Cost',
        totalEquipmentPayment: 'Contract Equipment Payment',
        servicePayment:'Contract Service Payment',
        assetBrand: 'Asset Brand',
        assetModel: 'Asset Model',
        assetSerialNumber: 'Asset Serial Number',
        assetDescription: 'Asset Description',
        contractStartDate: 'Contract Start date',
        contractTerm: 'Contract Term',
        contractMaturityDate: 'Projected Initial Expire Date',
        numofPaymentRemaining: 'Number of Payments Remaining',
        conPurchaseOpt: 'Contract Purchase Option',
        conPaymentfreq: 'Contract Payment Frequency',
        conType: 'Contract Type',
        conSignerName: 'Contract Signer Name',
        daysPastdue:'Number of Days Past Due',
        lastpayRcdDate: 'Last Payment Received Date',
       // custAccNum:'Customer Account Number',
        custAddressline1:'Customer Address Line 1',
        custCity:'Customer City',
        custState:'Customer State',
        custPostalcode:'Customer Postal Code',
        custPhnum:'Customer Phone Number',
        astAddress1: 'Asset Address Line 1',
        astAddress2: 'Asset Address Line 2',
        astCity: 'Asset City',
        astState: 'Asset State',
        astPostalCode: 'Asset Postal Code',
        astBillingAdd1: 'Asset Billing Address Line 1',
        astBillingAdd2: 'Asset Billing Address Line 2',
        astBillingCity: 'Asset Billing City',
        astBillingState: 'Asset Billing State',
        astBillingPstCode: 'Asset Billing Postal',
        salesRep:'Sales Rep'

       };
    

    connectedCallback() {
        //Get initial chunk of data with offset set at 0
        this.getRecords();
        //Commenting the below callback method - this will improve the performance
       // this.getDownloadRecords();
    }

     
    getRecords() { 
        if (this.offSet == 0){

            getTotalRecords()
                .then(result => {
                     
                    result = JSON.stringify(result);
                    if(result){ 
                         
                        this.totalRecords=result;
                        if (this.totalRecords > 20)
                            this.itemCount = 20 + '+';
                        else   
                            this.itemCount = result;
                        if (this.filter != null){
                            this.itemCount = this.portfoliolist.length;
                            console.log('checking search length');
                        }
                    }
                }) 
                .catch(error => {
                    this.error = error;
                    this.data = undefined;
                    console.log('error : ' + JSON.stringify(this.error));
                    this.showToast('Something went wrong', JSON.stringify(this.error), 'error');
                    return;
                });
        }

         
        getRecords({offSetCount : this.offSet, months: this.searchDate, status: this.searchStatus, orderByField: this.orderByField, orderByDirection : this.orderByDirection, filter :this.filter })
            .then(result => {
                console.log('inside get records ' +this.offSet);
                let preparedLeases = [];
                result = JSON.parse(result);
                console.log(result);
                if (result) {
                    result.forEach(contract => {     
                       
                        let preparedLease = {}; 
                        preparedLease.Id = contract.contract.Id;
                        preparedLease.contractNumber = contract.contract.Name;
                        if (contract.contract.End_User__r) {
                            if (contract.contract.End_User__r.Name) {
                                preparedLease.customerName = contract.contract.End_User__r.Name;
                                preparedLease.endUserURL = window.location.origin + '/dllondemand/s/account/' + contract.contract.End_User__c;
                            }
                        }
                        
                        if(contract.contract.Opportunity__r) {
                            if(contract.contract.Opportunity__r.Partner_Sales_Rep__r) {
                                preparedLease.salesRep =  contract.contract.Opportunity__r.Partner_Sales_Rep__r.Name;
                            } else {
                                preparedLease.salesRep = '';
                            }
                        }

                        //if ( contract.contract.Sales_Rep_Name__c)
                        //preparedLease.salesRep = contract.contract.Sales_Rep_Name__c;
                        preparedLease.financeType = contract.contract.Purchase_Option__c;   
                        preparedLease.term = contract.contract.Contract_Term_months__c;
                        preparedLease.remainPay = contract.contract.Payments_Remaining__c;
                        preparedLease.serials = contract.serial;
                        preparedLease.makes = contract.make;
                        preparedLease.health = contract.contract.Delinquency_Status__c;
                        preparedLease.status = contract.contract.Status_Text__c;
                        preparedLease.contractUrl = window.location.origin + '/dllondemand/s/contract/' +  contract.contract.Id;

                        //console.log('prepared lease : ' + JSON.stringify(preparedLease));
                        preparedLeases.push(preparedLease);
                    });
                    this.portfoliolist = [...this.portfoliolist, ...preparedLeases];
										this.savelist = this.portfoliolist;
                     
                    console.log('size of list' + this.portfoliolist.length);
                    this.itemCount = this.portfoliolist.length;
                    this.error = undefined;
                    this.loadMoreStatus = '';
                     
                    if (this.portfoliolist.length < 20){
                        this.isLoading = false;
                        this.loadMoreStatus = 'No more data to load';
                    }
                     
                    if (this.targetDataTable && this.targetDataTable.length >= this.maxRows) {
                        //stop Infinite Loading when threshold is reached
                        this.targetDataTable.enableInfiniteLoading = false;
                        //Display "No more data to load" when threshold is reached
                        this.loadMoreStatus = 'No more data to load';
                    }
                     
                    //Disable a spinner to signal that data has been loaded
                    if (this.targetDataTable){
                        this.targetDataTable.isLoading = false;
                    }
                     
                }
                else{
                    this.loadMoreStatus = 'No more data to load';
                    this.targetDataTable.isLoading = false;
                    return;
                }
            }) 
            .catch(error => {
                this.error = error;
                this.data = undefined;
                console.log('error : ' + JSON.stringify(this.error));
                this.showToast('Something went wrong', JSON.stringify(this.error), 'error');
                return;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

        
    /*to get All records for - Download Portfolio*/
    /*code to download Portfolio */
    handleDownload(event) {
       
        let date = new Date()
        let day = date.getDate();
        let month = date.getMonth()+1;
        let year = date.getFullYear();
        let fullDate = month + "-" + day + "-" + year;
        getdownloadRecords({months:this.searchDate, status:this.searchStatus, filter:this.filter})
        .then(res => {
           this.downloaddata= res;     
           console.log('downloaddata => '+this.downloaddata);

       
        if(!this.downloaddata || !this.downloaddata.length){
            
            return null
        }
        const jsonObject = JSON.stringify(this.downloaddata);
        const result = this.convertToCSV(jsonObject, this.headers);
        if(result === null) return
        const blob = new Blob([result])
        const exportedFilename = 'Portfolio' + fullDate +'.csv';
        if(navigator.msSaveBlob){
            navigator.msSaveBlob(blob, exportedFilename)
        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)){
            const link = window.document.createElement('a')
            link.href='data:text/csv;charset=utf-8,' + encodeURI(result);
            link.target="_blank"
            link.download=exportedFilename
            link.click()
        } else {
            const link = document.createElement("a")
            if(link.download !== undefined){
                const url = URL.createObjectURL(blob)
                link.setAttribute("href", url)
                link.setAttribute("download", exportedFilename)
                link.style.visibility='hidden'
                document.body.appendChild(link)
                link.click()
                document.body.removeChild(link)
            }
        }

    }) 
    }


     convertToCSV(objArray, headers){
        
        const columnDelimiter = ','
        const lineDelimiter = '\r\n'
        const actualHeaderKey = Object.keys(headers)
        const headerToShow = Object.values(headers) 
        let str = ''
        str+=headerToShow.join(columnDelimiter) 
        str+=lineDelimiter
        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray
    
        data.forEach(obj=>{
            let line = ''
            actualHeaderKey.forEach(key=>{
                if(line !=''){
                    line+=columnDelimiter
                }
                let strItem = obj[key]+''
                line+=strItem? strItem.replace(/,/g, ''):strItem
            })
            str+=line+lineDelimiter
        })
        console.log("str", str)
        return str
    } 
    /* end of Download Portfolio */

    loadMoreData(event) {
         
        event.preventDefault();
        // increase the offset count by 20 on every loadmore event
        this.offSet = this.offSet + 20;

        if (this.offSet > 20)
            this.itemCount = this.offSet + '+';

        //Display a spinner to signal that data is being loaded
        this.isLoading = true;
        event.target.isLoading = true;
        //Set the onloadmore event taraget to make it visible to imperative call response to apex.
        this.targetDataTable = event.target;
        //Display "Loading" when more data is being loaded
        this.loadMoreStatus = 'Loading';
        // Get new set of records and append to this.data
        this.getRecords();
         
    }

    //Geetha added to handle logic for select date filter
    handleChangeDate(event) {
        this.searchDate = event.target.value;
        console.log('this.searchDate ' +this.searchDate);
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.portfoliolist = [];
        this.rowOffset = 0;
        this.getRecords();
    }

    handleChange(event) {

        this.isLoading=true;
        this.searchDate = event.detail.value;
        this.portfoliolist = [];
        this.offSet = 0;
        this.searchStatus = 'ALL';
        this.getRecords();
        
    }

    handleChangeStatus(event) {

        this.isLoading=true;
        this.searchStatus = event.detail.value;
        this.portfoliolist = [];
        this.offSet = 0;
        this.getRecords();
        
    }

    /*Commenting this method as its a duplicate*/
    /*handleChange(event) {
        console.log('filter is' + event.detail.value);

        this.isLoading=true;
        this.filter = event.detail.value;
        
    }*/

    resetList(event) {

        console.log('value:' + event.detail.value);

        if(event.detail.value){
            console.log('returnning');
            
            return;
        }
        else{
            console.log('reset list'); 
            this.filter = '';
            this.portfoliolist = [];
            this.portfoliolist = this.savelist;
            this.isLoading=true;
            this.getRecords();
        }
    }

    
    handleFilter(event){
     
        if (event.keyCode == 13){
            this.filter = event.target.value;
            this.portfoliolist = [];
            this.isLoading=true;
            this.offSet = 0;
            this.getRecords();
        }
    }

    updateColumnSorting(event) {
        //new code Geetha - to fix the column sorting issue 
        this.orderByField = event.detail.fieldName;
        this.orderByDirection = event.detail.sortDirection;
        console.log('this.sortBy ' +this.orderByField);
        console.log('this.sortDirection ' +this.orderByDirection);
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.portfoliolist = [];
        this.rowOffset = 0;
        this.getRecords();
    }
}