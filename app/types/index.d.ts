import type { Avatar } from '#ui/types'

export type UserStatus = 'subscribed' | 'unsubscribed' | 'bounced'

export interface User {
  id: number
  name: string
  email: string
  avatar?: Avatar
  status: UserStatus
  location: string
}

export interface Mail {
  id: number
  unread?: boolean
  from: User
  subject: string
  body: string
  date: string
}

export interface Member {
  name: string
  username: string
  role: 'member' | 'owner'
  avatar: Avatar
}
export interface Test{
  Input: string,
  ExpeectedOutput:string
}
export interface Question{
  Title: string
  Description: string
  Level: number
  ID: string
  InputTypes: string
  Outputtype: string 
}
export interface Notification {
  id: number
  unread?: boolean
  sender: User
  body: string
  date: string
  tests: Test[]
}

export type Period = 'daily' | 'weekly' | 'monthly'

export interface Range {
  start: Date
  end: Date
}
