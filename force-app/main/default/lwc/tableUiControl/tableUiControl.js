import { LightningElement, track, api } from 'lwc';
import {reduceErrors,showPopUpNotification} from 'c/ldsUtils';

export default class TableUiControl extends LightningElement {
    @track _columns = [];
    @track _data = [];
    @track _inputcolumns;
    @track _gridColMet = [];   
    @track isLoaded;
    oldproductid = '';    
    @track showModal;
    @track tempRow = {};
    editMode = false;
    @api currentUserLocale;
    @api tableName;
    @api quoteStatus = '';
    @api sectionWiseCss = '';
    @api headerIconName = '';
    @api offriddstr; 
    @api showadddelbtn;
    @api btnname ='';
    @api offercurrency;
    @api sectionName;
    @api isDisabled;
    @api selectedUserId;

    @api
    get columns() {       
        return this._columns;
    }

    set columns(value) {      
        this._columns = value;
    }

    @api
    get rows() {
        return this._data;
    }

    set rows(value) {    
        this._data = value;      
    }

    //for the dropdown list
    @api
    get gridcolmet() {
        return this._gridColMet;
    }

    set gridcolmet(value) {
        this._gridColMet = value;
    }
    
    /*Purpose: to pass the latest table data to parent comp for saving the quote when user clicks on select customer button
    Parameters: objLst: to pass the list of records data
                Title: title of the table
                delProdid: id of the product to be deleted
                currentRowChangeDetails : to have the row details that user changed
    */
    createSaveQuoteLst(objList,title,val,delprodid){
        const selectEvent = new CustomEvent('savequotelst', {           
            detail: {value : objList, deletebtn: title, currentval : val, oldprodid: delprodid}
        });       
        this.dispatchEvent(selectEvent);
    }

    thousandsSeparators(num){
        var num_parts = num.toString().split(".");
        num_parts[0] = num_parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return num_parts.join(".");
    }
    
    /**
     * dispatch event on change of offer
    */
    handleofferchange(event){
        this.isLoaded = true;
        let result1 = event.detail;       
        const selectEvent = new CustomEvent('offerchangefromtable', {
            detail: result1
        });       
        this.dispatchEvent(selectEvent);
        this.isLoaded = false;
    }

    /**
     * dispatch event on change of fields in offer table
    */
    handleOfferFieldsChange(event){       
        let offerfeilds =  event.detail.colmData;
        let offerParameterPickListVal = event.detail.value;
        let retRecArr = [];
        
        offerfeilds['operation'] = 'update';
        retRecArr.push(offerfeilds);
        this._data = retRecArr;       
        this.createSaveQuoteLst(this._data,'null',offerParameterPickListVal,this.oldproductid);
    }

    /**
     * Purpose: Called on change of unit, unit price, insurance (for manager), rv (for manager) and product column, on blur of specification column
     */
    handleInputChange(event){
        const changedval = event.detail.value; 
        if(event.detail.oldprodctId != '')
            this.oldproductid = event.detail.oldprodctId;
        let tempdata = this._data;

        let retRecArr = [];
        try{
            for(let eachdata in tempdata){
                const colData = {};
                var objName = tempdata[eachdata]; //getting each columnName   
                     
                    for(let eachObj in objName){
                        if(objName['uid'] == event.detail.index){ //check for which uid number[unique key]
                            if(event.detail.changedcol == eachObj){ //check which cell was changed
                                if(event.detail.changedcol == 'quantity'){                     
                                    const unitprcval= objName['unitprice'];                               
                                    const result = event.detail.value * unitprcval;
                                    colData['uid'] = objName['uid'];                               
                                    colData['Product'] = objName['Product'];   
                                    colData['productname'] = objName['productname'];   
                                    if(typeof(objName['specification']) !== 'undefined')
                                        colData['specification'] = objName['specification'];
                                    colData['quantity'] = event.detail.value;
                                    colData['unitprice'] = objName['unitprice'];
                                    //colData['totalprice'] = this.thousandsSeparators(result);
                                    colData['totalprice'] = result.toFixed(2);
                                    colData['curencycode'] = this.offercurrency;
                                    colData['service'] = 'service'+objName['uid'];   
                                    colData['quotelineid'] = objName['quotelineid'];                            
                                    colData['operation'] = objName['quotelineid'] != '' ? 'update':'add'; 
                                    colData['productType'] = event.detail.productType;
                                    colData['isItadApplicable'] = objName['isItadApplicable'];
                                    colData['insuranceAmount'] = objName['insuranceAmount'];
                                    colData['residualValue'] = objName['residualValue'];
                                    colData['isInsuranceAvailable'] = objName['isInsuranceAvailable'];
                                    colData['isPurchaseOptionAvailable'] = objName['isPurchaseOptionAvailable'];
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    }                  
                                        
                                }else if(event.detail.changedcol == 'unitprice'){                               
                                    const unitquantval= objName['quantity'];                              
                                    const result = event.detail.value * unitquantval;
                                    colData['uid'] = objName['uid'];                              
                                    colData['Product'] = objName['Product'];
                                    colData['productname'] = objName['productname'];   
                                    if(typeof(objName['specification']) !== 'undefined')
                                        colData['specification'] = objName['specification'];
                                    colData['quantity'] = objName['quantity'];
                                    colData['unitprice'] = event.detail.value;
                                    //colData['totalprice'] = this.thousandsSeparators(result);
                                    colData['totalprice'] = result.toFixed(2);
                                    colData['curencycode'] = this.offercurrency;
                                    colData['service'] = 'service'+objName['uid'];
                                    colData['quotelineid'] = objName['quotelineid'];
                                    colData['operation'] = objName['quotelineid'] != '' ? 'update':'add';
                                    colData['productType'] = event.detail.productType;
                                    colData['isItadApplicable'] = objName['isItadApplicable'];
                                    //colData['insuranceAmount'] = objName['insuranceAmount'];
                                    colData['insuranceAmount'] = '';
                                    //colData['residualValue'] = objName['residualValue'];
                                    colData['residualValue'] = '';
                                    colData['isInsuranceAvailable'] = objName['isInsuranceAvailable'];
                                    colData['isPurchaseOptionAvailable'] = objName['isPurchaseOptionAvailable'];
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    } 
                                }  
                                else if(event.detail.changedlabel == 'Product'){                             
                                    colData['uid'] = objName['uid'];
                                    colData['Product'] = changedval.includes('-') ? changedval.substr(0, changedval.indexOf('-')) : changedval;
                                    colData['productname'] = changedval.split('-').pop(); 
                                    colData['specification'] = '';
                                    colData['quantity'] = changedval.split('-').pop() != '' ? objName['quantity'] : '';
                                    colData['unitprice'] = changedval.split('-').pop() != '' ? objName['unitprice'] : '';
                                    colData['totalprice'] = changedval.split('-').pop() != '' ? objName['totalprice'] :'0';
                                    colData['curencycode'] = this.offercurrency;
                                    colData['quotelineid'] = '';
                                    colData['operation'] = 'add';
                                    colData['productType'] = event.detail.productType;                             
                                    colData['isItadApplicable'] = event.detail.isItadApplicable;
                                    colData['insuranceAmount'] = null;
                                    colData['residualValue'] = null;
                                    colData['isInsuranceAvailable'] = event.detail.isInsuranceAvailable;
                                    colData['isPurchaseOptionAvailable'] = event.detail.isPurchaseOptionAvailable;
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    }
                                }else if(event.detail.changedlabel == 'Type'){                             
                                    colData['uid'] = objName['uid'];
                                    colData['Product'] = changedval.includes('-') ? changedval.substr(0, changedval.indexOf('-')) : changedval;
                                    colData['productname'] = changedval.split('-').pop();
                                    colData['quantity'] = changedval.split('-').pop() != '' ? objName['quantity'] : '';
                                    colData['unitprice'] = changedval.split('-').pop() != '' ? objName['unitprice'] : '';
                                    colData['totalprice'] = changedval.split('-').pop() != '' ? objName['totalprice'] :'0';
                                    colData['curencycode'] = this.offercurrency;
                                    colData['service'] = 'service'+objName['uid'];
                                    colData['quotelineid'] = '';
                                    colData['operation'] = 'add';
                                    colData['productType'] = event.detail.productType;
                                    colData['isItadApplicable'] = objName['isItadApplicable'];
                                    colData['insuranceAmount'] = objName['insuranceAmount'];
                                    colData['residualValue'] = objName['residualValue'];
                                    colData['isInsuranceAvailable'] = objName['isInsuranceAvailable'];
                                    colData['isPurchaseOptionAvailable'] = objName['isPurchaseOptionAvailable'];
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    }
                                }
                                else if(event.detail.changedcol == 'specification'){
                                    colData['uid'] = objName['uid'];
                                    colData['Product'] = objName['Product'];
                                    colData['productname'] = objName['productname'];   
                                    colData['specification'] = changedval;
                                    colData['quantity'] = objName['quantity'];
                                    colData['unitprice'] = objName['unitprice'];
                                    colData['totalprice'] = objName['totalprice'];
                                    colData['curencycode'] = this.offercurrency;
                                    colData['quotelineid'] = objName['quotelineid'];
                                    colData['operation'] = objName['quotelineid'] != '' ? 'update':'add';
                                    colData['productType'] = event.detail.productType;
                                    colData['isItadApplicable'] = objName['isItadApplicable'];
                                    colData['insuranceAmount'] = objName['insuranceAmount'];
                                    colData['residualValue'] = objName['residualValue'];
                                    colData['isInsuranceAvailable'] = objName['isInsuranceAvailable'];
                                    colData['isPurchaseOptionAvailable'] = objName['isPurchaseOptionAvailable'];
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    } 
                                } else if(event.detail.changedcol == 'insuranceAmount'){
                                    colData['uid'] = objName['uid'];
                                    colData['Product'] = objName['Product'];
                                    colData['productname'] = objName['productname']; 
                                    colData['specification'] = (objName['specification'] !== 'undefined') ? objName['specification'] : '';
                                    colData['quantity'] = objName['quantity'];
                                    colData['unitprice'] = objName['unitprice'];
                                    colData['totalprice'] = objName['totalprice'];
                                    colData['curencycode'] = this.offercurrency;
                                    colData['quotelineid'] = objName['quotelineid'];
                                    colData['operation'] = objName['quotelineid'] != '' ? 'update':'add';
                                    colData['productType'] = event.detail.productType;
                                    colData['isItadApplicable'] = objName['isItadApplicable'];
                                    colData['insuranceAmount'] = changedval;
                                    colData['residualValue'] = objName['residualValue'];
                                    colData['isInsuranceAvailable'] = objName['isInsuranceAvailable'];
                                    colData['isPurchaseOptionAvailable'] = objName['isPurchaseOptionAvailable'];
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    } 
                                } else if(event.detail.changedcol == 'residualValue'){
                                    colData['uid'] = objName['uid'];
                                    colData['Product'] = objName['Product'];
                                    colData['productname'] = objName['productname']; 
                                    colData['specification'] = (objName['specification'] !== 'undefined') ? objName['specification'] : '';
                                    colData['quantity'] = objName['quantity'];
                                    colData['unitprice'] = objName['unitprice'];
                                    colData['totalprice'] = objName['totalprice'];
                                    colData['curencycode'] = this.offercurrency;
                                    colData['quotelineid'] = objName['quotelineid'];
                                    colData['operation'] = objName['quotelineid'] != '' ? 'update':'add';
                                    colData['productType'] = event.detail.productType;
                                    colData['isItadApplicable'] = objName['isItadApplicable'];
                                    colData['insuranceAmount'] = objName['insuranceAmount'];
                                    colData['residualValue'] = changedval;
                                    colData['isInsuranceAvailable'] = objName['isInsuranceAvailable'];
                                    colData['isPurchaseOptionAvailable'] = objName['isPurchaseOptionAvailable'];
                                    if(event.detail.tableName == 'Product' && objName['uid'] == 1){
                                        colData['isDelBtnHide'] = true;
                                    } 
                                }
                            }
                            
                        }else{
                            colData[eachObj] = objName[eachObj];
                        }
                    }            
                    retRecArr.push(colData);
            }
            this._data = retRecArr;
            this.createSaveQuoteLst(this._data,'null','null',this.oldprodctId);
            this.updateTotalPrice(retRecArr);
        }catch(error){
            showPopUpNotification(
                this,
                reduceErrors(error), 
                'error'
            );
        }              
    }

    /**
     * get the total price for product table and dispatch
     */
    updateTotalPrice(result){
        let i =0;
        if(result.length == 0){
            const selectEvent = new CustomEvent('gettotalprice', {
                detail: 0
            });       
            this.dispatchEvent(selectEvent); //to update the final price
            return;
        }
        for(let eachres in result){
            let recLst = result[eachres];           
            for(let eachcol in recLst){               
                if(eachcol.includes('specification')){
                    let j = recLst['totalprice'];
                    let flotnum = parseFloat(j);                  
                    i += flotnum;                                     
                    const selectEvent = new CustomEvent('gettotalprice', {
                        detail: i
                    });       
                    this.dispatchEvent(selectEvent); //to update the final price
                } 
            }
        }    
    }

    handleRowAction(event) {
        let tempdata = JSON.parse(JSON.stringify(this._data));
        tempdata.splice(event.target.value, 1);       
        this._data = tempdata;
    }

    /**
     * delete the selected row
     */
    deleteSelectedRow(deleteRow) {
       
        let newData = JSON.parse(JSON.stringify(this._data));
        newData = newData.filter(row => row.uid !== deleteRow.uid);
        newData.splice(deleteRow.target.value, 1);    
        newData.forEach((element, index) => element.uid = index + 1);      
        this._data = newData;
        this.updateTotalPrice(newData); //to update final price on delete
        this.createSaveQuoteLst(this._data,deleteRow.target.title,'null',this.oldprodctId);      
    }

    /**
     * handling cancel functionality
     */
    handleCancel() {
        this.tempRow = {};
        this.showModal = false;
        this.editMode = false;
        this.editindex = undefined;
    }

    handleAddRow() {
        this.tempRow = {};
    }

    /**
     * create/add a row on click of Add button
     */
    handleRowAddition(event) {
        let newData = JSON.parse(JSON.stringify(this._data));
        if (!this.editMode) {
            // you can use any unique and required field instead of 'uid'.
            //calculate ui
            this.tempRow.uid = this._data.length + 1;
            //added all keys
            this.tempRow.Product = ''; 
            if(event.target.title == 'Products'){
                this.tempRow.specification = ''; 
            }else if(event.target.title == 'Services'){
                this.tempRow.Service = '';
            }		    
			this.tempRow.quantity = ''; 
			this.tempRow.unitprice = ''; 
            this.tempRow.totalprice = '0'; 
            this.tempRow.curencycode = this.offercurrency; 
            this.tempRow.quotelineid = '';
            this.tempRow.operation = 'add';
            this.tempRow.isItadApplicable = false;
            this.tempRow.insuranceAmount = null;
            this.tempRow.residualValue = null;
            newData.push(this.tempRow);       
        } else {
            newData[this.editindex] = this.tempRow;
            this.editindex = undefined;
            this.editMode = false;
        }

        this._data = newData;
        this.createSaveQuoteLst(this._data,'null','null',this.oldprodctId);
        this.tempRow = {};
        this.showModal = false;
    }

    openEditForm(editRow) {
        this.editindex = this._data.findIndex(row => row.uid === editRow.uid);
        this.tempRow = { ...this._data[this.editindex] };
        this._inputcolumns.forEach(element => element.displayValue = this.tempRow[element.fieldName]);
        this.showModal = true;
    }
}