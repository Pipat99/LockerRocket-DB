"use strict";

const STORAGE_KEY = "lockerrocket-demo-v1";
const emptyData = () => ({ campuses: [], members: [], lockers: [], reservations: [] });

function readData() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (saved && ["campuses", "members", "lockers", "reservations"].every((key) => Array.isArray(saved[key]))) {
      return saved;
    }
  } catch {
    // Replace invalid or unavailable demo data with an empty workspace.
  }
  return emptyData();
}

let data = readData();
const byId = (rows, id) => rows.find((row) => row.id === id);
const isOpen = (reservation) => ["pending", "active"].includes(reservation.status);
const form = (id) => document.getElementById(id);
const message = document.getElementById("message");

function save() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    return true;
  } catch {
    showMessage("Unable to save browser demo data. Check your browser storage settings.", true);
    return false;
  }
}

function showMessage(text, isError = false) {
  message.textContent = text;
  message.classList.toggle("error", isError);
}

function addOption(select, value, label) {
  const option = document.createElement("option");
  option.value = value;
  option.textContent = label;
  select.append(option);
}

function updateSelects() {
  const campusSelect = form("locker-form").elements.campusId;
  const memberSelect = form("reservation-form").elements.memberId;
  const lockerSelect = form("reservation-form").elements.lockerId;
  const selectedCampus = campusSelect.value;
  const selectedMember = memberSelect.value;
  const selectedLocker = lockerSelect.value;

  campusSelect.replaceChildren();
  addOption(campusSelect, "", data.campuses.length ? "Select a campus" : "Add a campus first");
  data.campuses.forEach((campus) => addOption(campusSelect, campus.id, campus.name));
  campusSelect.value = selectedCampus;
  campusSelect.disabled = data.campuses.length === 0;

  memberSelect.replaceChildren();
  addOption(memberSelect, "", data.members.length ? "Select a member" : "Add a member first");
  data.members.forEach((member) => addOption(memberSelect, member.id, `${member.firstName} ${member.lastName}`));
  memberSelect.value = selectedMember;
  memberSelect.disabled = data.members.length === 0;

  const availableLockers = data.lockers.filter((locker) =>
    locker.status === "available" &&
    !data.reservations.some((reservation) => reservation.lockerId === locker.id && isOpen(reservation))
  );
  lockerSelect.replaceChildren();
  addOption(lockerSelect, "", availableLockers.length ? "Select a locker" : "No available lockers");
  availableLockers.forEach((locker) => {
    const campus = byId(data.campuses, locker.campusId);
    addOption(lockerSelect, locker.id, `${locker.lockerNumber} · ${campus?.name ?? "Unknown campus"}`);
  });
  lockerSelect.value = selectedLocker;
  lockerSelect.disabled = availableLockers.length === 0;
}

function appendCell(row, value) {
  const cell = document.createElement("td");
  cell.textContent = value;
  row.append(cell);
  return cell;
}

function formatDate(value) {
  return new Date(value).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

function render() {
  updateSelects();
  document.getElementById("campus-count").textContent = data.campuses.length;
  document.getElementById("member-count").textContent = data.members.length;
  document.getElementById("locker-count").textContent = data.lockers.length;
  document.getElementById("reservation-count").textContent = data.reservations.filter(isOpen).length;

  const reservationRows = document.getElementById("reservation-rows");
  reservationRows.replaceChildren();
  data.reservations.slice().reverse().forEach((reservation) => {
    const member = byId(data.members, reservation.memberId);
    const locker = byId(data.lockers, reservation.lockerId);
    const campus = locker && byId(data.campuses, locker.campusId);
    const row = document.createElement("tr");
    appendCell(row, member ? `${member.firstName} ${member.lastName}` : "Unknown member");
    appendCell(row, locker?.lockerNumber ?? "Unknown locker");
    appendCell(row, campus?.name ?? "Unknown campus");
    appendCell(row, `${formatDate(reservation.startsAt)} – ${formatDate(reservation.endsAt)}`);
    const status = appendCell(row, "");
    const badge = document.createElement("span");
    badge.className = `status ${reservation.status}`;
    badge.textContent = reservation.status;
    status.append(badge);
    const action = appendCell(row, "");
    if (isOpen(reservation)) {
      const cancel = document.createElement("button");
      cancel.className = "cancel-button";
      cancel.type = "button";
      cancel.textContent = "Cancel";
      cancel.setAttribute("aria-label", `Cancel reservation for ${member?.firstName ?? "member"}`);
      cancel.addEventListener("click", () => {
        reservation.status = "cancelled";
        if (save()) {
          render();
          showMessage("Reservation cancelled.");
        }
      });
      action.append(cancel);
    }
    reservationRows.append(row);
  });
  document.getElementById("empty-state").hidden = data.reservations.length > 0;

  const lockerRows = document.getElementById("locker-rows");
  lockerRows.replaceChildren();
  data.lockers.forEach((locker) => {
    const row = document.createElement("tr");
    appendCell(row, locker.lockerNumber);
    appendCell(row, byId(data.campuses, locker.campusId)?.name ?? "Unknown campus");
    appendCell(row, locker.size);
    const occupied = data.reservations.some((reservation) => reservation.lockerId === locker.id && isOpen(reservation));
    appendCell(row, occupied ? "Reserved" : locker.status);
    lockerRows.append(row);
  });
  document.getElementById("locker-empty-state").hidden = data.lockers.length > 0;
}

function addRecord(collection, record, successText) {
  data[collection].push({ id: crypto.randomUUID(), ...record });
  if (save()) {
    render();
    showMessage(successText);
  }
}

form("campus-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const values = new FormData(event.currentTarget);
  const code = values.get("code").trim();
  if (data.campuses.some((campus) => campus.code.toLowerCase() === code.toLowerCase())) {
    showMessage("Campus code must be unique.", true);
    return;
  }
  addRecord("campuses", {
    code,
    name: values.get("name").trim(),
    address: values.get("address").trim()
  }, "Campus added.");
  event.currentTarget.reset();
});

form("member-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const values = new FormData(event.currentTarget);
  const universityId = values.get("universityId").trim();
  const email = values.get("email").trim();
  if (data.members.some((member) =>
    member.universityId.toLowerCase() === universityId.toLowerCase() ||
    member.email.toLowerCase() === email.toLowerCase()
  )) {
    showMessage("University ID and email must each be unique.", true);
    return;
  }
  addRecord("members", {
    universityId,
    firstName: values.get("firstName").trim(),
    lastName: values.get("lastName").trim(),
    email,
    phone: values.get("phone").trim()
  }, "Member added.");
  event.currentTarget.reset();
});

form("locker-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const values = new FormData(event.currentTarget);
  const campusId = values.get("campusId");
  const lockerNumber = values.get("lockerNumber").trim();
  if (data.lockers.some((locker) =>
    locker.campusId === campusId && locker.lockerNumber.toLowerCase() === lockerNumber.toLowerCase()
  )) {
    showMessage("Locker number must be unique within its campus.", true);
    return;
  }
  addRecord("lockers", {
    campusId,
    lockerNumber,
    size: values.get("size"),
    status: "available"
  }, "Locker added.");
  event.currentTarget.reset();
});

form("reservation-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const values = new FormData(event.currentTarget);
  const startsAt = new Date(values.get("startsAt"));
  const endsAt = new Date(values.get("endsAt"));
  const lockerId = values.get("lockerId");
  const occupied = data.reservations.some((reservation) =>
    reservation.lockerId === lockerId && isOpen(reservation)
  );
  if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime()) || endsAt <= startsAt) {
    showMessage("Reservation end time must be later than its start time.", true);
    return;
  }
  if (occupied) {
    showMessage("This locker already has a pending or active reservation.", true);
    render();
    return;
  }
  addRecord("reservations", {
    memberId: values.get("memberId"),
    lockerId,
    startsAt: startsAt.toISOString(),
    endsAt: endsAt.toISOString(),
    status: "pending"
  }, "Reservation created.");
  event.currentTarget.reset();
});

document.getElementById("reset-demo").addEventListener("click", () => {
  if (!window.confirm("Remove all RocketLocker demo records from this browser?")) return;
  data = emptyData();
  if (save()) {
    render();
    showMessage("Demo data reset.");
  }
});

render();
