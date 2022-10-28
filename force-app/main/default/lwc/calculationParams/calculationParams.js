import { LightningElement, api } from 'lwc';
import { constants } from 'c/ldsUtils';

export default class CalculationParams extends LightningElement {
    @api calculationParams;
    displayCalculationParams;
    labels = constants;

    /* Financed Amount Columns */
    financedAmountColumns = [
        { label: "Financed Amount Name", fieldName : "financedAmountName", display : "lwc.output", source : "text"},
        { label: "Financed Amount Value",  fieldName : "financedAmountNameValue", display : "lwc.output", source : "text"}, 
    ];

    /* Rate Columns */
    rateColumns = [
        { label: "Rate Name", fieldName : "rateName", display : "lwc.output", source : "text"},
        { label: "Rate Value",  fieldName : "rateValue", display : "lwc.output", source : "text"}, 
    ];

    /* Lease Calculation Columns */
    leaseCalculationColumns = [
        { label: "Lease Calculation Name", fieldName : "leaseCalculationName", display : "lwc.output", source : "text"},
        { label: "Lease Calculation Value",  fieldName : "leaseCalculationValue", display : "lwc.output", source : "text"}, 
    ];

    /* Residual Value Columns */
    residualValueColumns = [
        { label: "Product Name", fieldName : "productName", display : "lwc.output", source : "text"},
        { label: "RV Matrix",  fieldName : "rvMatrix", display : "lwc.output", source : "text"}, 
        { label: "Category Name", fieldName : "category", display : "lwc.output", source : "text"},
        { label: "RV Value",  fieldName : "rvValue", display : "lwc.output", source : "text"}, 
    ];

    /* Residual Value Columns */
    purchaseOptionColumns = [
        { label: "Product Name", fieldName : "productName", display : "lwc.output", source : "text"},
        { label: "Purchase Option Value",  fieldName : "purchaseOption", display : "lwc.output", source : "text"}, 
    ];

    /* Insurance Columns */
    insuranceColumns = [
        { label: "Product Name", fieldName : "productName", display : "lwc.output", source : "text"},
        { label: "Insurance Code",  fieldName : "insuranceCode", display : "lwc.output", source : "text"}, 
        { label: "Insurance Value",  fieldName : "insuranceValue", display : "lwc.output", source : "text"}, 
    ];

    /* This object stores all data for calculation tables */
    calcutationTables = [
        {tableName: "Financed Amount", tableKey: "financedAmount", class: "slds-col slds-size_1-of-2", colspan: "2", tdStyles: "width: 50%;", data: [], columns: this.financedAmountColumns},
        {tableName: "Rate", tableKey: "rate", class: "slds-col slds-size_1-of-2", colspan: "2", tdStyles: "width: 50%;", data: [], columns: this.rateColumns },
        {tableName: "Lease Calculation", tableKey: "leaseCalculation", class: "slds-col slds-size_1-of-1", tdStyles: "width: 50%;", colspan: "2", data: [], columns: this.leaseCalculationColumns},
        {tableName: "Residual Value", tableKey: "residualValue", class: "slds-col slds-size_1-of-1", tdStyles: "width: 25%;", colspan: "4", data: [], columns: this.residualValueColumns},
        {tableName: this.labels.Purchase_Option, tableKey: "purchaseOption", class: "slds-col slds-size_1-of-1", tdStyles: "width: 50%;", colspan: "2", data: [], columns: this.purchaseOptionColumns},
        {tableName: "Insurance", tableKey: "insurance", class: "slds-col slds-size_1-of-1", colspan: "3", tdStyles: "width: 33%;", data: [], columns: this.insuranceColumns},
    ];

    /* get data (row value) for calcutationTables object and return object for iteration in html markup*/
    get data() {
        if (!this.calculationParams) {
            return;
        }
        this.calcutationTables.forEach(item => {
            item.data = this.getTableParams(item.tableKey);
        });

        let data = this.calcutationTables;
        return data;
    }

    /* get data for tables from parent and form new arr for table rows */
    getTableParams(tableName) {
        let arr = [];

        for (let key in this.calculationParams[tableName]) {
            if (tableName === 'financedAmount') {
                arr.push({
                    financedAmountName: key,
                    financedAmountNameValue: this.calculationParams[tableName][key]
                });
            } else if (tableName === 'rate') {
                arr.push({
                    rateName: key,
                    rateValue: this.calculationParams[tableName][key]
                });
            } else if (tableName === 'leaseCalculation') {
                arr.push({
                    leaseCalculationName: key,
                    leaseCalculationValue: this.calculationParams[tableName][key]
                });
            } else if (tableName === 'residualValue') {
                this.calculationParams[tableName][key].forEach(item => {
                    arr.push({
                        productName: item['productName'],
                        rvMatrix: item['rvMatrix'],
                        category: item['category'],
                        rvValue: item['rvValue'],
                    });
                });
            } else if (tableName === 'purchaseOption') {
                this.calculationParams[tableName][key].forEach(item => {
                    arr.push({
                        productName: item['productName'],
                        purchaseOption: item['purchaseOption'],
                    });
                });
            } else if (tableName === 'insurance') {
                this.calculationParams[tableName][key].forEach(item => {
                    arr.push({
                        productName: item['productName'],
                        insuranceCode: item['insuranceCode'],
                        insuranceValue: item['insuranceValue'],
                    });
                });
            }
        }

        return arr.length > 0 ? arr : false;
    }

    connectedCallback() {
        this.displayCalculationParams = true;
    }
}