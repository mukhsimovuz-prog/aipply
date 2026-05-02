import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm'

const supabaseUrl = 'https://plvaufqatovuljfzxjaz.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsdmF1ZnFhdG92dWxqZnp4amF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MDY4OTIsImV4cCI6MjA5MzI4Mjg5Mn0.V3HV2WbOYIRS2bElLsKmObaIsUGusLC2ba6Bqgti-kE'

export const supabase = createClient(supabaseUrl, supabaseKey)
