import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["calendarContainer", "hiddenField"];
  static values = { endDate: String };

  connect() {
    const rawDate = this.hiddenFieldTarget.value; // Get the raw value from the hidden field
    let initialDate;

    if (rawDate) {
      // Format the raw date to YYYY-MM-DD and set it as the hidden field value
      const formattedDate = this.formatDateToLocalISO(new Date(rawDate));
      this.hiddenFieldTarget.value = formattedDate;
      initialDate = new Date(formattedDate);
    } else {
      // Default to today's date if the hidden field is empty
      initialDate = new Date();
      this.hiddenFieldTarget.value = this.formatDateToLocalISO(initialDate);
    }

    this.selectedDate = new Date(initialDate);
    this.renderCalendar(this.selectedDate);
  }

  formatDateToLocalISO(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }

  renderCalendar(date) {
    const calendarContainer = this.calendarContainerTarget;
    calendarContainer.innerHTML = ""; // Clear existing calendar

    const year = date.getFullYear();
    const month = date.getMonth();

    // Create calendar header
    const header = document.createElement("div");
    header.className = "calendar-header";
    const monthName = date.toLocaleString("default", { month: "long" });
    header.innerHTML = `
      <button class="prev-month">&lt;</button>
      <span class="month-year">${monthName} ${year}</span>
      <button class="next-month">&gt;</button>
    `;
    calendarContainer.appendChild(header);

    // Event listeners for navigation
    header.querySelector(".prev-month").addEventListener("click", () => {
      this.renderCalendar(new Date(year, month - 1, 1));
    });
    header.querySelector(".next-month").addEventListener("click", () => {
      this.renderCalendar(new Date(year, month + 1, 1));
    });

    // Create days of the week row
    const daysRow = document.createElement("div");
    daysRow.className = "calendar-days";
    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].forEach((day) => {
      const dayElement = document.createElement("div");
      dayElement.className = "day-name";
      dayElement.textContent = day;
      daysRow.appendChild(dayElement);
    });
    calendarContainer.appendChild(daysRow);

    // Get the first and last days of the month
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);

    // Get the start and end dates for rendering
    const startDate = new Date(firstDay);
    startDate.setDate(startDate.getDate() - firstDay.getDay());

    const endDate = new Date(lastDay);
    endDate.setDate(lastDay.getDate() + (6 - lastDay.getDay()));

    // Create the calendar grid
    const grid = document.createElement("div");
    grid.className = "calendar-grid";

    for (let tempDate = new Date(startDate); tempDate <= endDate; tempDate.setDate(tempDate.getDate() + 1)) {
      const currentDate = new Date(tempDate); // Clone tempDate for event listener
      const dayCell = document.createElement("div");
      dayCell.className = "calendar-day";
      dayCell.textContent = currentDate.getDate();

      if (currentDate.getMonth() !== month) {
        dayCell.classList.add("other-month");
      }

      // Highlight the selected date
      if (
        currentDate.getFullYear() === this.selectedDate.getFullYear() &&
        currentDate.getMonth() === this.selectedDate.getMonth() &&
        currentDate.getDate() === this.selectedDate.getDate()
      ) {
        dayCell.classList.add("selected");
      }

      // Event listener for selecting a date
      dayCell.addEventListener("click", () => {
        this.selectedDate = new Date(currentDate); // Clone the current date
        this.hiddenFieldTarget.value = this.formatDateToLocalISO(this.selectedDate);
        this.renderCalendar(date); // Re-render calendar with updated selection
      });

      grid.appendChild(dayCell);
    }

    calendarContainer.appendChild(grid);
  }
}