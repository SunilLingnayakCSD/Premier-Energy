import { LightningElement, track, wire } from 'lwc';
import getFilteredTurnover from '@salesforce/apex/TurnOverController.getFilteredTurnover';
import getProductsByMonthYear from '@salesforce/apex/TurnOverController.getProductsByMonthYear';
import getAllProducts from '@salesforce/apex/HomeOrderControllers.getAllProducts';

export default class TradeHub extends LightningElement {
    @track date1;
    @track date2;
    @track date3;
    @track date4;

    @track monthlyData = [];
    @track quarterlyData = [];
    @track yearlyData = [];
    @track datarecords = [];
    @track currentMonthLabel;
    @track isLoading = false;

    connectedCallback() {
        this.defaultdata();
        this.functioncall();
    }

    // Set default dates to last month
    defaultdata() {
        const today = new Date();
        const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1);
        const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0);

        // Format as YYYY-MM-DD
        this.date1 = lastMonthStart.toISOString().split('T')[0];
        this.date2 = lastMonthEnd.toISOString().split('T')[0];
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

    // Wire method to fetch TOD data
    @wire(getFilteredTurnover, { startDate: '$date1', endDate: '$date2' })
    wiredTurnover({ data, error }) {
        this.isLoading = true;
        if (data) {
            console.log('TOD Data:', data);
            
            // Process monthly data with formatted period labels
            this.monthlyData = (data['Month'] || []).map((item, index) => {
                const periodDate = new Date(item.validFrom);
                const monthName = periodDate.toLocaleString('default', { month: 'long' });
                return { 
                    ...item, 
                    serialNumber: index + 1,
                    periodLabel: `${monthName.toUpperCase()} ${periodDate.getFullYear()}`,
                    formattedTarget: this.formatNumber(item.matchedTarget),
                    formattedSales: this.formatNumber(item.totalActualMwp),
                    formattedPayout: this.formatCurrency(item.netPayout)
                };
            });
            
            // Process quarterly data
            this.quarterlyData = (data['Quarter'] || []).map((item, index) => {
                return { 
                    ...item, 
                    serialNumber: index + 1,
                    periodLabel: item.periodLabel || `Q${index + 1}`,
                    formattedTarget: this.formatNumber(item.matchedTarget),
                    formattedSales: this.formatNumber(item.totalActualMwp),
                    formattedPayout: this.formatCurrency(item.netPayout)
                };
            });
            
            // Process yearly data
            this.yearlyData = (data['Year'] || []).map((item, index) => {
                return { 
                    ...item, 
                    serialNumber: index + 1,
                    periodLabel: item.periodLabel || `FY ${new Date(item.validFrom).getFullYear()}-${new Date(item.validTo).getFullYear()}`,
                    formattedTarget: this.formatNumber(item.matchedTarget),
                    formattedSales: this.formatNumber(item.totalActualMwp),
                    formattedPayout: this.formatCurrency(item.netPayout)
                };
            });
            
        } else if (error) {
            console.error('Error fetching turnover data:', error);
            this.showToast('Error', error.body.message, 'error');
        }
        this.isLoading = false;
    }

    // Format number with commas and 2 decimal places
    formatNumber(value) {
        if (value === null || value === undefined) return '0.00';
        return new Intl.NumberFormat('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    // Format currency with symbol and 2 decimal places
    formatCurrency(value) {
        if (value === null || value === undefined) return '₹0.00';
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    // Set current month label
    functioncall() {
        const now = new Date();
        const month = now.toLocaleString('default', { month: 'long' });
        const year = now.getFullYear();
        this.currentMonthLabel = `${month.toUpperCase()} ${year}`;
    }

    // Wire method to fetch product data
    @wire(getAllProducts)
    wiredProducts({ error, data }) {
        console.log('OUTPUT :---data---- ',data);
        if (data) {
        console.log('OUTPUT :---data---- ',data);
            this.datarecords = data.map((item, index) => ({

                ...item,
                serialNumber: index + 1,
                formattedPrice: this.formatCurrency(item.price)
            }));
            console.log('OUTPUT :this.datarecords ',this.datarecords);
        } else if (error) {
            console.error('Error fetching product data:', error.body.message);
            this.showToast('Error', error.body.message, 'error');
        }
    }

    // Fetch turnover data for specific month/year range
    fetchTurnoverData() {
        const startParts = this.date3 ? this.date3.split('-') : [];
        const endParts = this.date4 ? this.date4.split('-') : [];
        
        const startYear = startParts.length ? parseInt(startParts[0], 10) : null;
        const startMonth = startParts.length ? parseInt(startParts[1], 10) : null;
        const endYear = endParts.length ? parseInt(endParts[0], 10) : null;
        const endMonth = endParts.length ? parseInt(endParts[1], 10) : null;
        
        this.isLoading = true;
        getProductsByMonthYear({
            startYear,
            startMonth,
            endYear,
            endMonth
        })
        .then(result => {
            this.datarecords = result.map((item, index) => ({
                ...item,
                serialNumber: index + 1,
                formattedPrice: this.formatCurrency(item.price)
            }));
        })
        .catch(error => {
            console.error('Error:', error);
            this.showToast('Error', error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    // Helper method to show toast messages
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
}