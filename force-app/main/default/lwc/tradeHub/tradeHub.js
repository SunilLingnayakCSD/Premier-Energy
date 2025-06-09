import { LightningElement,track,wire} from 'lwc';
import getFilteredTurnover from '@salesforce/apex/TurnOverController.getFilteredTurnover';
import getProductsByMonthYear from '@salesforce/apex/TurnOverController.getProductsByMonthYear';

import getAllProducts from '@salesforce/apex/HomeOrderControllers.getAllProducts'

export default class TradeHub extends LightningElement {
    @track date1;
    @track date2;
    @track date3;
    @track date4

    @track monthlyData = [];
    @track quarterlyData = [];
    @track yearlyData = [];
    @track datarecords = [];
    @track selectedMonth;
    @track selectedYear;
    @track products = [];


    // date1 = new Date(new Date().getFullYear(), 0, 1).toISOString().split('T')[0]; // Jan 1
    // date2 = new Date().toISOString().split('T')[0]; // Today

    // handleDateChange(event) {
    //     const fieldName = event.target.name;
    //     console.log('fieldName',fieldName);
        
    //     const value = event.target.value;
    //     console.log('value',value);

    //     if (fieldName === 'startDate') {
    //         this.date1 = value;
    //     } else if (fieldName === 'endDate') {
    //         this.date2 = value;
    //     }
    // }

    //  @wire(getFilteredTurnover,{ startDate:'$date1',endDate:'$date2'})
    //     wiredTurnover({ data, error }) {
    //         if (data) {
    //             console.log('data',data);
                
    //             // this.monthlyData = data['Month'] || [];
    //             // this.quarterlyData = data['Quarter'] || [];
    //             // this.yearlyData = data['Year'] || [];
    //             this.monthlyData = this.addSerialNumbers(data['Month'] || []);
    //             console.log('month---',this.monthlyData);
                
                
    //             this.quarterlyData = this.addSerialNumbers(data['Quarter'] || []);
    //             console.log('quarterly----',this.quarterlyData);
    //             this.yearlyData = this.addSerialNumbers(data['Year'] || []);
    //             console.log('yearly---',  this.yearlyData);
    //         } else if (error) {
    //             console.error('Error fetching leads:', error);
    //         }

            
    //     }


    //     addSerialNumbers(dataList) {
    //         return dataList.map((item, index) => {
    //             return { ...item, serialNumber: index + 1 };
    //         });
    //     }


     // Calculate last month's start and end dates and set them
    defaultdata() {
        console.log('called');
        
        const today = new Date();
        console.log('today',today);
        const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1); // First day of last month
        console.log('lastMonthStart',lastMonthStart);
        
        const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0); // Last day of last month
        console.log('lastMonthEnd',lastMonthEnd);

        // Format the dates to the correct format (yyyy-MM-dd)
        this.date1 = lastMonthStart.toISOString().split('T')[0]; // Start of last month
        console.log('this.date1',this.date1);
        this.date2 = lastMonthEnd.toISOString().split('T')[0]; // End of last month
        console.log('this.date2',this.date2);
    }

    // Handle date change events
    handleDateChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;

        if (fieldName === 'startDate') {
            this.date1 = value;
        } else if (fieldName === 'endDate') {
            this.date2 = value;
        }
    }

    // Wire the Apex method to fetch filtered turnover data
    @wire(getFilteredTurnover, { startDate: '$date1', endDate: '$date2' })
    wiredTurnover({ data, error }) {
        if (data) {
            console.log('data:', data);
            this.monthlyData = this.addSerialNumbers(data['Month'] || []);
            console.log('monthlyData:', this.monthlyData);

            this.quarterlyData = this.addSerialNumbers(data['Quarter'] || []);
            console.log('quarterlyData:', this.quarterlyData);

            this.yearlyData = this.addSerialNumbers(data['Year'] || []);
            console.log('yearlyData:', this.yearlyData);
        } else if (error) {
            console.error('Error fetching turnover data:', error);
        }
    }

    // Helper method to add serial numbers to the data
    addSerialNumbers(dataList) {
        return dataList.map((item, index) => {
            return { ...item, serialNumber: index + 1 };
        });
    }
      
        // @wire(getAllProducts)
        //     allProducts(result) {
        //         if (result.data) {
        //             // Flatten Product2.Name into ProductName
        //             this.datarecords = result.data.map((item, index)=> ({
        //                 ...item,
        //                 Id: item.Id,
        //                 productName: item.Product2?.Name, // optional chaining in case Product2 is null
        //                 price: item.UnitPrice,
        //                 serialNumber: index + 1 
        //             }));
        //             console.log('Flattened records:', this.datarecords);
        //         } else if (result.error) {
        //             console.error('Error fetching data:', result.error.body.message);
        //         }
        //     }
       @track currentMonthLabel;

    functioncall() {
        const now = new Date();
        console.log('now',now);
        
        const month = now.toLocaleString('default', { month: 'long' });
        console.log('month',month);
        const year = now.getFullYear();
        console.log('year',year);
        this.currentMonthLabel = `${month.toUpperCase()} ${year}`; // e.g. "APRIL 2025"
        console.log('currentMonthLabel',this.currentMonthLabel);
    }

    @wire(getAllProducts)
    wiredProducts({ error, data }) {
        if (data) {
            this.datarecords = data;
            console.log('Flattened current month data:', this.datarecords);
            this.functioncall();
        } else if (error) {
            console.error('Error fetching product data:', error.body.message);
        }
    }


            connectedCallback() {
                this.fetchTurnoverData();
                this.defaultdata();
            }
        
            // handleChangeDate(event) {
            //     const { name, value } = event.target;
        
            //     if (name === 'startDate') {
            //         this.date3 = value;
            //     } else if (name === 'endDate') {
            //         this.date4 = value;
            //     }
        
            //     if (this.date3 && this.date4) {
            //         this.fetchTurnoverData();
            //     }
            // }
        
            fetchTurnoverData() {
                const startParts = this.date3 ? this.date3.split('-') : [];
                const endParts = this.date4 ? this.date4.split('-') : [];
        
                const startYear = startParts.length ? parseInt(startParts[0], 10) : null;
                const startMonth = startParts.length ? parseInt(startParts[1], 10) : null;
                const endYear = endParts.length ? parseInt(endParts[0], 10) : null;
                const endMonth = endParts.length ? parseInt(endParts[1], 10) : null;
        
                getProductsByMonthYear({
                    startYear,
                    startMonth,
                    endYear,
                    endMonth
                })
                    .then(result => {
                        console.log('result------------>>>>>',result);
                        
                        this.datarecords = result.map((item, index) => ({
                            ...item,
                            serialNumber: index + 1
                        }));
                        console.log('datarecords------------>>>>>',this.datarecords);
                    })
                    .catch(error => {
                        console.error('Error:', error);
                    });
            }

           
}