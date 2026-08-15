# **Prana (ප්‍රාණ): Project overview**

*Read this first to get a full picture in one place. Written for everyone on the team.*

## **1\. What we're building**

**Prana (ප්‍රාණ)** is a mobile app that makes it easier for people in Sri Lanka to find and join blood donation events near them, and for the organizations running those events (hospitals, Leo/Lions clubs, schools, churches, NGOs) to manage donors and track who's actually shown up and donated.

### **The problem**

Most blood donation camps in Sri Lanka are organized by community groups, not by one central body. A donor who wants to give blood has no single place to see "what"s happening near me this week" across all of these organizers. The government does run an official system, **Raktha**, from the National Blood Transfusion Service (NBTS): but it's built around booking an appointment at a fixed blood bank, not discovering community-run camps.

### **Our solution**

Prana (ප්‍රාණ) sits in that gap: one app where a donor creates a profile once, sees nearby events from *any* organizer or hospital on a map, RSVPs, donates, and gets verified credit for it, building a donation history that follows them across every organization they donate with.

**Important:** we are not affiliated with, and must never present ourselves as, the NBTS or Raktha. We're a separate, non-profit community tool.

## **2\. Who it's for (the four roles)**

| Role | Who uses it | What they do |
| ----- | ----- | ----- |
| **Super admin** | Us, the dev team | Full control over the system |
| **Admin** | Light of Hope Foundation | Runs the platform day-to-day, onboards new organizers/hospitals |
| **Organizer portal** | Doctors, Leo/Lions clubs, schools, churches, NGOs | Create and manage donation camps/events |
| **Hospital portal** | Partner hospitals | Run their own drives, verify donations, and request blood when needed |
| **Donor dashboard** | The general public | Sign up, find events, RSVP, donate, and build a verified donation history |

## **3\. How it actually works: step by step**

1. Someone signs up with their name, age, location, NIC, and phone number, and sets a password.  
2. They log in with their **NIC**, as we use NIC instead of name as the identifier because it's guaranteed to be unique per person.  
3. The app asks for their location (not a dropdown of cities, since that's easy to get wrong) and shows nearby donation events and hospitals on a map.  
4. They pick an event and RSVP: "I'm coming to donate."  
5. On the day, they show up, get screened, and donate.  
6. The hospital or organizer scans a **QR code** on the donor's account to confirm the donation happened. This flips their status to **verified donor**.  
7. Verified donors get recognition in the app and keep getting notified about relevant nearby events. Verified status isn't permanent; it needs refreshing periodically so it reflects someone who's actually still an active donor.

## **4\. What's in scope now vs. later**

**Now (core build):** the four dashboards above, the donor signup/discovery/RSVP/verification flow described in Section 3\.

**Later (Phase 2):** an analytics module, breaking down donation data by disease relevance, blood type, age, gender, and other factors. This is planned but not part of the first version, so don't worry about building for it yet, though if you're working on the database, flag it to the leads so we don't have to awkwardly retrofit fields later.

## **5\. Tech stack (plain-language version)**

* **Flutter:** what the app itself is built in (this is what makes it work on both Android and iPhone from one codebase)  
* **Go:** the backend, i.e., the server that handles logins, stores data requests, and talks to the database  
* **Supabase:** the database, where all the accounts, events, and donation records actually live

## 

## 

## 

## **6\. How we're organized as a team**

* **Leads:** Nipuna Lakruwan and Vimukthi Fernando, who handle architecture decisions, review every pull request, and merge changes into the main codebase.  
* **Contributors:** the rest of the team (Gewmini Gunrathne, Minindi Wimandika, Sankhani Wanninayaka), who pick up assigned tasks, build them on their own branch, and open a pull request when ready for review.  
* Nobody pushes directly to the main codebase, including leads; every change goes through review first. This isn't about trust; it's just good practice, and it's also how we'll show individual contribution clearly in our final report.  

## **7\. Non-profit commitment**

Prana (ප්‍රාණ) will always be free, with no charging donors or organizations, no selling donor data, and no one person owning or profiting from it individually. This was agreed by the whole founding team from day one.

## **8\. Where everything lives**

* **Project specification**: the full technical detail: roles, data flow, diagrams, deliverables list, timeline  
* **GitHub repos**: `mobile-app` and `web-dashboard`, both private, both under the Prana (ප්‍රාණ) organization

If anything in this document doesn't match what you understood the project to be, flag it to the leads before you start building against it; better to catch a mismatch now than after a few weeks of work.