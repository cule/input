/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef MERGINSUBSCRIPTIONSTATUS_H
#define MERGINSUBSCRIPTIONSTATUS_H
#pragma once

#include <QObject>

class MerginSubscriptionStatus
{
    Q_GADGET
  public:
    explicit MerginSubscriptionStatus();

    enum SubscriptionStatus
    {
      FreeSubscription,
      ValidSubscription,
      SubscriptionInGracePeriod,
      SubscriptionUnsubscribed
    };
    Q_ENUMS( SubscriptionStatus )
};

#endif // MERGINSUBSCRIPTIONSTATUS_H