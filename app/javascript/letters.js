document.addEventListener("focus", (event) => {
  if (!event.target.matches(".status-dropdown")) return;
  event.target.dataset.previousValue = event.target.value;
}, true);

document.addEventListener("change", (event) => {
  if (!event.target.matches(".status-dropdown")) return;

  if (event.target.value === "pending" && !confirm("This will requeue the letter for LLM processing. Continue?")) {
    event.target.value = event.target.dataset.previousValue || event.target.value;
    return;
  }

  const form = event.target.closest("form");
  const formData = new FormData();
  formData.append("status", event.target.value);
  formData.append("authenticity_token", document.querySelector('meta[name="csrf-token"]').content);

  fetch(form.action, {
    method: "PATCH",
    body: formData,
    headers: {
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      "Accept": "application/json",
      "X-Requested-With": "XMLHttpRequest"
    }
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(data => {
    const statusContainer = event.target.closest(".index-td");
    const pendingAtDiv = statusContainer.querySelector(".text-xs");
    const row = event.target.closest(".index-row");
    const newStatus = event.target.value;

    // Update background color
    if (newStatus === "precheck") {
      row.classList.remove("bg-white", "hover:bg-gray-50");
      row.classList.add("bg-red-50", "hover:bg-red-100");
    } else {
      row.classList.remove("bg-red-50", "hover:bg-red-100");
      row.classList.add("bg-white", "hover:bg-gray-50");
    }

    // Update Edit button visibility
    const editLink = row.querySelector('a[href*="dashboard"]');
    if (editLink) {
      editLink.style.display = newStatus === "precheck" ? "none" : "";
    }

    // Update precheck options visibility
    const precheckOptions = row.querySelector(".precheck-options");
    if (precheckOptions) {
      precheckOptions.style.display = newStatus === "precheck" ? "" : "none";
    }

    if (data.pending_at) {
      const date = new Date(data.pending_at);
      const formattedDate = date.toLocaleString('en-US', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
        timeZone: document.querySelector('meta[name="time-zone"]')?.content || 'UTC'
      }).replace(',', '');

      if (pendingAtDiv) {
        pendingAtDiv.textContent = `Pending since: ${formattedDate}`;
      } else {
        const newDiv = document.createElement("div");
        newDiv.className = "text-xs text-gray-500 mt-1";
        newDiv.textContent = `Pending since: ${formattedDate}`;
        statusContainer.appendChild(newDiv);
      }
    } else if (pendingAtDiv) {
      pendingAtDiv.remove();
    }
  })
  .catch(error => {
    console.error("Error updating status:", error);
    alert("Failed to update status. Please try again.");
  });
});