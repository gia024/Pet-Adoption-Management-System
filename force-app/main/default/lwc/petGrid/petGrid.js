import { LightningElement } from 'lwc';
import fetchFilteredPets from '@salesforce/apex/PetGridController.fetchFilteredPets';

export default class PetGrid extends LightningElement {
  pets = [];
  isLoading = false;
  showFlow = false;
  selectedPetId;

  filterCriteria = {
    breed: '',
    gender: '',
    minAge: null,
    maxAge: null
  };

  connectedCallback() {
    this.loadPets();
  }// calls loadPets() immediately so that users see the list of available pets right away

  handleFilterChange(event) {
    this.filterCriteria = { ...event.detail }; // spread operator to replace the object
    this.loadPets();
  }

  loadPets() {
    this.isLoading = true;
    fetchFilteredPets({
      breed: this.filterCriteria.breed,
      gender: this.filterCriteria.gender,
      minAge: this.filterCriteria.minAge,
      maxAge: this.filterCriteria.maxAge
    })
      .then(result => {
        this.pets = result;
      })
      .catch(error => {
        console.error('Error fetching pets', error);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleAdoptNow(event) {
    this.selectedPetId = event.target.dataset.id;
    this.showFlow = true;
  }

  handleCloseFlow() {
    this.showFlow = false;
    this.selectedPetId = null;
  }

  get inputVariables() {
    return [
      {
        name: 'PetId',
        type: 'String',
        value: this.selectedPetId
      }
    ];
  }

  handleFlowStatusChange(event) {
    if (event.detail.status === 'FINISHED') {
      this.handleCloseFlow();
      this.loadPets(); // refresh pet list
      window.location.reload();

    }
  }
}