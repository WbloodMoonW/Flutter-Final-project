# **Introduction**

## **Overview**

Angezny is a service marketplace platform available as both a web application and a
Flutter mobile application. The platform connects users with skilled service
providers such as electricians, plumbers, carpenters, and other maintenance
professionals. Users can easily browse services, request help, and communicate with
providers through a simple and modern interface.
The project aims to simplify the process of finding trusted workers for home and
maintenance services while giving service providers a digital platform to reach
more customers.

## Goals

- Provide an easy-to-use platform for requesting home services.
- Connect customers with qualified service providers quickly.
- Support multiple service categories in one system.
- Create a responsive experience across web and mobile platforms.
- Improve service management and communication between users and providers.
- Build a scalable and organized service marketplace.
Target Audience
Customers
- People looking for maintenance or home services.
- Users searching for trusted professionals quickly.
Service Providers
- Electricians
- Plumbers
- Carpenters
- Technicians
- Freelance workers and maintenance specialists
Administrators
- System managers responsible for monitoring users, services, and platform activity.

# User Guide

### **Getting Started**

Open the Application
Users can access Angezny through:

- The web application
- The Flutter mobile application

When you first open Angezny, you're on the home page. You'll see a search bar, featured service categories, and some worker cards. You can browse a bit without logging in, but to actually book anything, you need an account.

## **For Customers**

#### *1. Creating an account*

1. Hit "إنشاء حساب" (Sign Up) and fill in your name, email, and password
2. You'll get a verification email. Click the link inside before you can do anything
3. If you prefer, you can sign in with Google directly (no email verification needed)

#### *2. Finding a worker*

1. Use the search bar on the home page to search by service type (e.g., "سباكة" or "كهرباء")
2. Or browse by category; the home page shows clickable category chips
3. The services page has filters for category, price range, and rating
4. Click on any worker card to open their full profile

#### *3. Booking a service*

1. On the worker's profile, you'll see their services listed with pricing
2. Click "طلب الخدمة" on the service you want
3. Fill in your address (there's a map picker), describe what you need, and pick a payment method (cash or card)
4. Got a coupon? There's a promo code field at checkout
5. Submit the request; the worker gets notified and can accept or reject it

#### *4. During & after the job*

1. Once a worker accepts, you can open a live chat with them directly from the order
2. You'll get real-time notifications when the worker updates the order status
3. When the job's done, the worker marks it complete and uploads a completion report
4. You can then leave a star rating and a written review

#### *5. Other things you can do*

- Save workers to your favorites list (the heart icon on any worker card)
- Message any worker before booking through the messages page
- Open a support ticket if something goes wrong
- Edit your profile info and picture from /profile/edit

## **For Workers (Service Providers)**

#### *1. Registering as a worker*

1. On the signup page, toggle to "مزود خدمة" before submitting
2. Verify your email
3. You'll be redirected to set up your worker profile

#### *2. Setting up your profile*

1. Add a profile photo and write a short bio
2. Pick your main service category and add extra categories if relevant
3. Set your availability (which days and hours you work)
4. Add your skills as tags
5. Upload portfolio items, photos, and descriptions of past work
6. Add service packages with pricing (fixed, hourly, or a price range)
7. If you have a professional license, upload it; the admin will review it

#### *3. Managing orders*

1. New booking requests appear in your dashboard with a notification
2. You can accept or reject each request (add a rejection reason if you decline)
3. Accepted orders appear in "الطلبات الجارية"
4. When you finish a job, mark it complete and upload a quick completion report
5. You can also rate the customer after completing an order

#### *4. Earnings & wallet*

- Each completed order credits your in-app wallet automatically
- You can see your balance and transaction history in the dashboard

## **For Admins**

Admins access the platform at /admin. The dashboard only shows up if your account role is "admin.”

- Verify or reject worker profiles and uploaded licenses
- Manage service categories (add, edit, delete)
- Create and manage discount coupons
- Handle user reports and support tickets
- View analytics — orders, revenue, most active workers, etc.
- Ban or suspend users if needed

# System Design & Architecture

## OverView

Angezny is actually built across three separate clients that all talk to the same backend: a web app (Next.js), a mobile app (Flutter), and an admin panel (part of the web app). They all hit the same REST API deployed on Render and share the same MongoDB Atlas database.

Web App (Next.js)  +  Mobile App (Flutter)
↕ REST API
Node.js + Express
↕
MongoDB Atlas

## **Web App**

- **Framework:** Next.js 16 + React 19 + TypeScript
- **Styling:** Tailwind CSS + shadcn/ui
- **State Management:** React Context API + TanStack React Query
- **Forms:** react-hook-form + Zod validation
- **Maps:** Leaflet / react-leaflet
- **HTTP:** Axios
- **Real-time:** Socket.IO client
- **Deployment:** Vercel

## **Mobile App**

- **Framework:** Flutter (Dart) — Android & iOS
- **State Management:** Provider
- **HTTP:** http package
- **Local Storage:** shared_preferences (token + session)
- **Maps:** flutter_map + latlong2
- **Image Picking:** image_picker
- **Fonts & Icons:** google_fonts + font_awesome_flutter

## **Backend**

- **Runtime:** Node.js + Express 5
- **Database:** MongoDB Atlas + Mongoose
- **Auth:** JWT + bcrypt + Google OAuth (google-auth-library)
- **Real-time:** Socket.IO
- **Email:** Brevo
- **File Storage:** Cloudinary
- **Security:** express-rate-limit + CORS

# **Implementation Overview**

## **How we built it**

We split the work into two separate parts backend first, then the two frontends (web and mobile) in parallel. We started by setting up the database models and auth, then built the API routes one feature at a time. The web and mobile were both hitting the same API so we used Postman to test endpoints and make sure everything was working before connecting the UI

### **UI/UX Design**

- Designing Arabic-first RTL interfaces for both web and mobile
- Creating simple booking workflows that work for non-tech-savvy users
- Organizing separate dashboards for customers, workers, and admins
- Keeping the mobile and web experience consistent in terms of flow and terminology

## **Development**

The implementation included:

- Authentication system with JWT, email verification, and Google OAuth
- Service request and order management system with a full status lifecycle
- Worker and customer dashboards tailored to each role
- Real-time chat and notifications via Socket.IO
- Search system with autocomplete and trending suggestions
- Coupon and discount system
- Worker ranking algorithm based on rating, activity, and profile completeness
- Admin panel with analytics, user management, and worker verification
- Responsive web app built with Next.js and a cross-platform mobile app built with Flutter

### **Testing**

Testing was performed to ensure:

- All API endpoints return correct responses and handle edge cases
- Order status transitions work correctly and cannot be skipped
- JWT authentication works consistently across both web and mobile
- Forms validate properly on both client and server side
- The app handles network errors gracefully with meaningful Arabic messages

### **Challenges Faced**

- Keeping the experience consistent across two completely different tech stacks (Next.js and Flutter) while sharing the same backend
- Making the application simple and easy to use for both customers and workers across web and mobile, regardless of their technical background
- Finding the right balance between security and performance — things like JWT validation, rate limiting, and password hashing add protection but also overhead, so we had to make sure they didn't slow the app down
- Making the platform clear and understandable for everyone, whether they're a customer booking their first service or a worker managing multiple orders at once
- Managing the order lifecycle with multiple status transitions and edge cases like cancellation requests
- Structuring the backend to serve both web and mobile clients without duplicating logic

## **Conclusion**

Angezny provides a modern digital solution for connecting customers with skilled service providers across Egypt. The project was built on a MERN stack backend serving both a Next.js web app and a Flutter mobile app — two completely different frontends sharing one API. It demonstrates how real-world concepts like role-based auth, real-time communication, and marketplace ranking can be implemented in a full-stack project, and lays a solid foundation that can scale into a production-ready platform.
